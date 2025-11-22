import PDFKit

@MainActor
final class SavedDocumentsListViewModel: ObservableObject {
    // MARK: Properties
    @Published private(set) var documents: [PDFDocumentEntityModel] = []
    @Published var showingShareSheet: Bool = false
    @Published var itemsToShare: [Any] = []

    @Published var showingMergeSheet = false
    @Published var mergeFirstDocument: PDFDocumentEntityModel?
    @Published var mergeSecondDocument: PDFDocumentEntityModel?
    @Published var newDocumentTitle: String = ""

    var availableDocumentsForMerge: [PDFDocumentEntityModel] {
        documents.filter { $0.id != mergeFirstDocument?.id }
    }

    private let storageService: DocumentStorageProtocol
    private let pdfGenerator: PDFGeneratorService

    // MARK: Init
    init(
        storageService: DocumentStorageProtocol = DocumentStorageService(),
        pdfGenerator: PDFGeneratorService = PDFGeneratorService()
    ) {
        self.storageService = storageService
        self.pdfGenerator = pdfGenerator
        Task { await loadDocuments() }
    }

    // MARK: Methods
    func loadDocuments() async {
        documents = await storageService.fetchAll()
    }

    func deleteDocument(id: UUID) {
        Task {
            await storageService.delete(id: id)
            documents.removeAll { $0.id == id }
        }
    }

    func share(_ document: PDFDocumentEntityModel) {
        guard let url = temporaryPDFUrl(from: document) else { return }
        itemsToShare = [url]
        showingShareSheet = true
    }

    func startMerge(_ firstDocument: PDFDocumentEntityModel) {
        mergeFirstDocument = firstDocument
        mergeSecondDocument = nil
        newDocumentTitle = ""
        showingMergeSheet = true
    }

    func selectSecondDocument(_ secondDocument: PDFDocumentEntityModel) {
        mergeSecondDocument = secondDocument
        if let first = mergeFirstDocument {
            newDocumentTitle = "\(first.title) + \(secondDocument.title)"
        }
    }

    func cancelMerge() {
        mergeFirstDocument = nil
        mergeSecondDocument = nil
        newDocumentTitle = ""
        showingMergeSheet = false
    }

    func createMergedDocument() {
        guard let first = mergeFirstDocument, let second = mergeSecondDocument else { return }
        mergeDocuments([first, second], newTitle: newDocumentTitle)
        cancelMerge()
    }

    // MARK: Private methods
    private func uniqueTitle(for title: String) async -> String {
        let existingTitles = await storageService.getAllDocumentsTitles()
        if !existingTitles.contains(title) { return title }
        var index = 1
        var newTitle: String
        repeat {
            newTitle = "\(title) (\(index))"
            index += 1
        } while existingTitles.contains(newTitle)
        return newTitle
    }

    private func temporaryPDFUrl(from document: PDFDocumentEntityModel) -> URL? {
        do {
            let data = try Data(contentsOf: document.fileURL)
            let uniqueName = document.title + "_temp.pdf"
            return FileStorage.shared.save(data: data, name: uniqueName)
        } catch {
            print("Ошибка чтения PDF для временного файла:", error)
            return nil
        }
    }

    private func mergeDocuments(_ docs: [PDFDocumentEntityModel], newTitle: String) {
        Task { @MainActor in
            guard !docs.isEmpty else { return }

            var pdfDocs: [PDFDocument] = []
            for doc in docs {
                if let pdf = PDFDocument(url: doc.fileURL) { pdfDocs.append(pdf) }
            }
            guard !pdfDocs.isEmpty else { return }

            let mergedPDF = PDFDocument()
            var pageIndex = 0
            for pdf in pdfDocs {
                for i in 0..<pdf.pageCount {
                    if let page = pdf.page(at: i)?.copy() as? PDFPage {
                        mergedPDF.insert(page, at: pageIndex)
                        pageIndex += 1
                    }
                }
            }

            guard let pdfData = mergedPDF.dataRepresentation() else { return }
            let finalTitle = await uniqueTitle(for: newTitle)
            let newURL = FileStorage.shared.save(data: pdfData, name: "\(finalTitle).pdf")

            guard let savedURL = newURL else { return }

            let thumbnail: Data
            if let firstPage = mergedPDF.page(at: 0) {
                let pageRect = firstPage.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                let img = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(pageRect)
                    firstPage.draw(with: .mediaBox, to: ctx.cgContext)
                }
                thumbnail = img.jpegData(compressionQuality: 0.8) ?? Data()
            } else {
                thumbnail = Data()
            }

            let newDocument = PDFDocumentEntityModel(
                id: UUID(),
                title: finalTitle,
                fileExtension: "pdf",
                createdAt: Date(),
                thumbnail: thumbnail,
                fileURL: savedURL
            )

            await storageService.save(newDocument)
            await loadDocuments()
        }
    }

    private func saveNewDocument(_ document: PDFDocumentEntityModel) {
        Task {
            let finalTitle = await uniqueTitle(for: document.title)
            let newDoc = PDFDocumentEntityModel(
                id: UUID(),
                title: finalTitle,
                fileExtension: document.fileExtension,
                createdAt: Date(),
                thumbnail: document.thumbnail,
                fileURL: document.fileURL
            )
            await storageService.save(newDoc)
            await loadDocuments()
        }
    }
}
