import SwiftUI
import PDFKit

@MainActor
final class PDFReaderViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published private(set) var pageCount: Int = 0
    @Published var selectedPages: Set<Int> = []
    @Published var isSelecting: Bool = false
    @Published var errorMessage: String?

    @Published var showAddTextSheet = false
    @Published var newTextForPage = ""

    @Published var showMergeNameAlert = false
    @Published var mergeDocumentName = ""

    @Published var revision: UUID = UUID()

    @Published var currentPageIndex: Int = 0

    private(set) var documentModel: PDFDocumentEntityModel
    private let storage: DocumentStorageProtocol
//    private let pdfGenerator = PDFGeneratorProtocol
    private let pdfGenerator = PDFGeneratorService()

    init(
        document: PDFDocumentEntityModel,
        storage: DocumentStorageProtocol = DocumentStorageService()
    ) {
        self.documentModel = document
        self.storage = storage
//        self.pdfGenerator = pdfGenerator
        loadPDF()
    }

    func reloadIfNeeded() {
        if pdfDocument == nil { loadPDF() }
    }

    func goToPage(_ index: Int) {
        guard let pdf = pdfDocument, index >= 0, index < pdf.pageCount else { return }
        NotificationCenter.default.post(name: .PDFReaderGoToPage, object: index)
        currentPageIndex = index
    }

    func thumbnail(at index: Int) -> UIImage? {
        guard let pdf = pdfDocument, index >= 0, index < pdf.pageCount else { return nil }
        guard let data = pdf.page(at: index)?.dataRepresentation else { return nil }
        return pdfGenerator.createThumbnail(from: data).flatMap { UIImage(data: $0) }
    }

    func page(at index: Int) -> PDFPage? {
        pdfDocument?.page(at: index)
    }

    func toggleSelectionMode() {
        isSelecting.toggle()
        if !isSelecting { selectedPages.removeAll() }
    }

    func toggleSelectPage(_ index: Int) {
        if selectedPages.contains(index) { selectedPages.remove(index) }
        else { selectedPages.insert(index) }
    }

    func deleteSelectedPagesAsync() async {
        guard let pdf = pdfDocument else { return }
        let sorted = selectedPages.sorted(by: >)
        guard !sorted.isEmpty else { return }

        for idx in sorted {
            if idx >= 0 && idx < pdf.pageCount {
                pdf.removePage(at: idx)
            }
        }

        rebuildPDFDocument(pdf)
        selectedPages.removeAll()
        revision = UUID()
    }

    func addTextPageAsync(text: String) {
        Task { await addTextPageInMemory(text: text) }
    }

    @MainActor
    func mergeSelectedPagesAsync(name: String) async {
        do {
            guard let source = pdfDocument else { throw PDFReaderError.noDocument }
            let indices = selectedPages.sorted()
            guard !indices.isEmpty else { throw PDFReaderError.noSelectedPages }

            let newPDF = PDFDocument()
            for idx in indices {
                guard let page = source.page(at: idx) else { continue }
                newPDF.insert(page.copy() as! PDFPage, at: newPDF.pageCount)
            }

            guard let data = newPDF.dataRepresentation(), !data.isEmpty else {
                throw PDFReaderError.saveFailed
            }

            let id = UUID()
            guard let url = FileStorage.shared.save(data: data, name: "\(id).pdf") else {
                throw PDFReaderError.saveFailed
            }

            let model = PDFDocumentEntityModel(
                id: id,
                title: name,
                fileExtension: "pdf",
                createdAt: Date(),
                thumbnail: pdfGenerator.createThumbnail(from: data) ?? Data(),
                fileURL: url
            )

            await storage.save(model)
            selectedPages.removeAll()
            revision = UUID()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveChangesAsync() async {
        do {
            try await commitChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPDF() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            guard let pdf = await PDFDocument(url: self.documentModel.fileURL) else {
                await MainActor.run { self.errorMessage = "Не удалось открыть PDF" }
                return
            }
            await MainActor.run {
                self.pdfDocument = pdf
                self.pageCount = pdf.pageCount
                self.revision = UUID()
            }
        }
    }

    private func addTextPageInMemory(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let pdf = pdfDocument else { return }

        let pageSize = CGSize(width: 595.2, height: 842.0)
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: pageSize))
            let inset = CGRect(x: 24, y: 24, width: pageSize.width - 48, height: pageSize.height - 48)
            let para = NSMutableParagraphStyle()
            para.alignment = .left
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .paragraphStyle: para,
                .foregroundColor: UIColor.black
            ]
            NSAttributedString(string: trimmed, attributes: attrs).draw(in: inset)
        }

        guard let pdfData = pdfGenerator.makePDF(from: [image]),
              let newPage = PDFDocument(data: pdfData)?.page(at: 0) else {
            errorMessage = "Не удалось создать PDF страницу"
            return
        }

        pdf.insert(newPage, at: pdf.pageCount)
        rebuildPDFDocument(pdf)
        revision = UUID()
    }

    private func commitChanges() async throws {
        guard let pdf = pdfDocument else { throw PDFReaderError.noDocument }
        guard let data = pdf.dataRepresentation() else { throw PDFReaderError.saveFailed }
        guard let savedURL = FileStorage.shared.save(data: data, name: "\(documentModel.id).pdf") else { throw PDFReaderError.saveFailed }

        let newModel = PDFDocumentEntityModel(
            id: documentModel.id,
            title: documentModel.title,
            fileExtension: documentModel.fileExtension,
            createdAt: Date(),
            thumbnail: pdfGenerator.createThumbnail(from: data) ?? Data(),
            fileURL: savedURL
        )

        await storage.save(newModel)
        documentModel = newModel
    }

    private func rebuildPDFDocument(_ pdf: PDFDocument) {
        if let data = pdf.dataRepresentation(), let rebuilt = PDFDocument(data: data) {
            pdfDocument = rebuilt
            pageCount = rebuilt.pageCount
        } else {
            pdfDocument = pdf
            pageCount = pdf.pageCount
        }
    }
}

// MARK: - Errors
enum PDFReaderError: Error {
    case noDocument
    case indexOutOfBounds
    case renderFailed
    case pageCreationFailed
    case saveFailed
    case noSelectedPages
}
