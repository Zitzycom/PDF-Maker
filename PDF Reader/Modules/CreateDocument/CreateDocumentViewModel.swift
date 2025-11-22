import SwiftUI
import PDFKit

@MainActor
final class CreateDocumentViewModel: ObservableObject {
    // MARK: Properties
    @Published var attachments: [Attachment] = []
    @Published var previewDocument: PDFDocumentEntityModel?
    @Published var savedDocument: PDFDocumentEntityModel?
    @Published var shareURL: URL?

    @Published var showImagePicker = false
    @Published var showDocumentPicker = false
    @Published var showPickerTypeDialog = false
    @Published var navigateToPDF = false
    @Published var isPresentingActivity = false

    private let storage: DocumentStorageProtocol

    var imagesBinding: Binding<[UIImage]> {
        Binding(
            get: { self.attachments.compactMap { if case let .image(img) = $0 { return img } else { return nil } } },
            set: { newImages in
                self.attachments.removeAll { if case .image = $0 { return true } else { return false } }
                self.attachments.append(contentsOf: newImages.map { Attachment.image($0) })
            }
        )
    }

    // MARK: Init
    init(storage: DocumentStorageProtocol = DocumentStorageService()) {
        self.storage = storage
    }

    // MARK: Methods
    func removeAttachment(at index: Int) {
        guard attachments.indices.contains(index) else { return }
        attachments.remove(at: index)
    }

    func addFiles(urls: [URL]) {
        for url in urls {
            let ext = url.pathExtension.lowercased()
            if ext == "pdf" { attachments.append(.pdf(url)) }
            else if ["png","jpg","jpeg"].contains(ext) {
                if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                    attachments.append(.image(img))
                } else { attachments.append(.other(url)) }
            } else {
                attachments.append(.other(url))
            }
        }
    }

    func createPreviewAsync() {
        guard !attachments.isEmpty else { return }
        Task.detached(priority: .userInitiated) { [attachmentsCopy = self.attachments] in
            guard let pdfData = await self.makePDF(from: attachmentsCopy),
                  let thumbData = await self.createThumbnail(from: pdfData) else { return }

            let id = UUID()
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(id).pdf")
            try? pdfData.write(to: tmpURL)

            let model = PDFDocumentEntityModel(
                id: id,
                title: "Preview \(Int.random(in: 1000...9999))",
                fileExtension: "pdf",
                createdAt: Date(),
                thumbnail: thumbData,
                fileURL: tmpURL
            )

            await MainActor.run { self.previewDocument = model }
        }
    }

    func savePreviewAsync() {
        guard let preview = previewDocument else { return }

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                let data = try Data(contentsOf: preview.fileURL)
                let newID = UUID()
                let uniqueTitle = await self.makeUniqueCopyTitle(baseTitle: preview.title)

                guard let savedURL = FileStorage.shared.save(data: data, name: "\(newID).pdf") else { return }

                let model = PDFDocumentEntityModel(
                    id: newID,
                    title: uniqueTitle,
                    fileExtension: preview.fileExtension,
                    createdAt: Date(),
                    thumbnail: preview.thumbnail,
                    fileURL: savedURL
                )

                await self.storage.save(model)
                await MainActor.run { self.savedDocument = model }
            } catch { }
        }
    }

    func sharePreview() {
        guard let _ = previewDocument else { return }
        prepareTempFileForSharing { url in
            guard let url = url else { return }
            self.shareURL = url
            self.isPresentingActivity = true
        }
    }

    func cleanupShare() {
        if let url = shareURL { try? FileManager.default.removeItem(at: url) }
        shareURL = nil
    }

    // MARK: Private methods
    private func makeUniqueCopyTitle(baseTitle: String) async -> String {
        let existingTitles = await storage.getAllDocumentsTitles()

        if !existingTitles.contains(baseTitle) {
            return baseTitle
        }

        var copyIndex = 0
        var candidate: String
        repeat {
            candidate = copyIndex == 0 ? "\(baseTitle) (копия)" : "\(baseTitle) (копия \(copyIndex))"
            copyIndex += 1
        } while existingTitles.contains(candidate)

        return candidate
    }

    private func prepareTempFileForSharing(completion: @escaping (URL?) -> Void) {
        guard let preview = previewDocument else { completion(nil); return }
        Task.detached(priority: .userInitiated) {
            do {
                let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("share-\(UUID().uuidString).pdf")
                if FileManager.default.fileExists(atPath: tmpURL.path) {
                    try FileManager.default.removeItem(at: tmpURL)
                }
                try FileManager.default.copyItem(at: preview.fileURL, to: tmpURL)
                await MainActor.run { completion(tmpURL) }
            } catch { await MainActor.run { completion(nil) } }
        }
    }

    private func makePDF(from attachments: [Attachment]) async -> Data? {
        let pageSize = CGSize(width: 595.2, height: 842.0)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)

        return renderer.pdfData { ctx in
            for attachment in attachments {
                switch attachment {
                case .image(let img):
                    ctx.beginPage()
                    let rect = CGRect(origin: .zero, size: pageSize)
                    let fitted = Self.aspectFitRect(imageSize: img.size, container: rect)
                    img.draw(in: fitted)

                case .pdf(let url):
                    guard let doc = PDFDocument(url: url) else {
                        ctx.beginPage()
                        let rect = CGRect(origin: .zero, size: pageSize)
                        let text = "Не удалось вставить PDF: \(url.lastPathComponent)"
                        text.draw(in: rect.insetBy(dx: 20, dy: 20), withAttributes: [.font: UIFont.systemFont(ofSize: 18)])
                        continue
                    }
                    for i in 0..<doc.pageCount {
                        guard let page = doc.page(at: i) else { continue }
                        ctx.beginPage()
                        let pageRect = page.bounds(for: .mediaBox)
                        let scale = min(pageSize.width / pageRect.width, pageSize.height / pageRect.height)
                        ctx.cgContext.saveGState()
                        ctx.cgContext.translateBy(x: 0, y: pageSize.height)
                        ctx.cgContext.scaleBy(x: 1, y: -1)
                        ctx.cgContext.scaleBy(x: scale, y: scale)
                        page.draw(with: .mediaBox, to: ctx.cgContext)
                        ctx.cgContext.restoreGState()
                    }

                case .other(let url):
                    ctx.beginPage()
                    let rect = CGRect(origin: .zero, size: pageSize)
                    let text = "Не поддерживаемый файл\n\(url.lastPathComponent)"
                    text.draw(in: rect.insetBy(dx: 20, dy: 20), withAttributes: [.font: UIFont.systemFont(ofSize: 20)])
                }
            }
        }
    }

    private func createThumbnail(from pdfData: Data) async -> Data? {
        guard let doc = PDFDocument(data: pdfData), let page = doc.page(at: 0) else { return nil }
        let targetSize = CGSize(width: 120, height: 150)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))
            let pageRect = page.bounds(for: .mediaBox)
            let fitted = Self.aspectFitRect(imageSize: pageRect.size, container: CGRect(origin: .zero, size: targetSize))
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: fitted.origin.x, y: fitted.origin.y)
            ctx.cgContext.scaleBy(x: fitted.size.width / pageRect.width, y: fitted.size.height / pageRect.height)
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }.pngData()
    }

    // MARK: Statics
    private static func aspectFitRect(imageSize: CGSize, container: CGRect) -> CGRect {
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let newSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(x: container.midX - newSize.width/2, y: container.midY - newSize.height/2)
        return CGRect(origin: origin, size: newSize)
    }

    enum Attachment {
        case image(UIImage)
        case pdf(URL)
        case other(URL)
    }
}
