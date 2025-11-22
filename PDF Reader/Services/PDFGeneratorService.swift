import PDFKit
import WebKit

protocol PDFGeneratorProtocol {
    func makePDF(from images: [UIImage]) -> Data?
    func createThumbnail(from pdfData: Data) -> Data?
    func convertFileToPDF(url: URL, completion: @escaping (Data?) -> Void)
}

final class PDFGeneratorService: NSObject, PDFGeneratorProtocol {
    private var webView: WKWebView?

    // MARK: - IMAGES → PDF
    func makePDF(from images: [UIImage]) -> Data? {
        let meta: [String: Any] = [
            kCGPDFContextCreator as String: "PDF Reader",
            kCGPDFContextAuthor as String: "User"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = meta

        let pageSize = CGSize(width: 595.2, height: 842.0)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize),
                                             format: format)

        return renderer.pdfData { ctx in
            for image in images {
                ctx.beginPage()
                let rect = CGRect(origin: .zero, size: pageSize)
                let fitted = Self.aspectFitRect(imageSize: image.size, container: rect)
                image.draw(in: fitted)
            }
        }
    }

    // MARK: - PDF → THUMBNAIL
    func createThumbnail(from pdfData: Data) -> Data? {
        guard let doc = PDFDocument(data: pdfData),
              let page = doc.page(at: 0) else {
            return nil
        }

        let targetSize = CGSize(width: 120, height: 150)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: targetSize))

            guard let pageRect = page.bounds(for: .mediaBox).optionalSizeRect else { return }

            let fitted = Self.aspectFitRect(
                imageSize: pageRect.size,
                container: CGRect(origin: .zero, size: targetSize)
            )

            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: fitted.origin.x, y: fitted.origin.y)
            ctx.cgContext.scaleBy(x: fitted.size.width / pageRect.size.width,
                                  y: fitted.size.height / pageRect.size.height)
            page.draw(with: .mediaBox, to: ctx.cgContext)
            ctx.cgContext.restoreGState()
        }

        return image.pngData()
    }

    // MARK: - DOC/DOCX/XLS/XLSX/PPT/PPTX → PDF
    func convertFileToPDF(url: URL, completion: @escaping (Data?) -> Void) {
        let webView = WKWebView(frame: .zero)
        self.webView = webView

        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())

        webView.navigationDelegate? = WebViewDelegate { [weak self] success in
            guard success else {
                completion(nil)
                return
            }

            let formatter = webView.viewPrintFormatter()

            let renderer = CustomPrintPageRenderer()
            renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

            let data = renderer.renderToPDF()
            completion(data)
            self?.webView = nil
        }
    }

    // MARK: - Helpers
    private static func aspectFitRect(imageSize: CGSize, container: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }

        let scale = min(container.width / imageSize.width,
                        container.height / imageSize.height)

        let newSize = CGSize(width: imageSize.width * scale,
                             height: imageSize.height * scale)

        let origin = CGPoint(
            x: container.midX - newSize.width / 2,
            y: container.midY - newSize.height / 2
        )

        return CGRect(origin: origin, size: newSize)
    }
}

// MARK: - WKWebView Delegate Wrapper
private final class WebViewDelegate: NSObject, WKNavigationDelegate {
    private let completion: (Bool) -> Void

    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        completion(true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        completion(false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        completion(false)
    }
}

// MARK: - Renderer
private final class CustomPrintPageRenderer: UIPrintPageRenderer {
    override init() {
        super.init()

        let page = CGRect(x: 0, y: 0, width: 595.2, height: 842.0)
        let printable = page.insetBy(dx: 20, dy: 20)

        setValue(page, forKey: "paperRect")
        setValue(printable, forKey: "printableRect")
    }

    func renderToPDF() -> Data {
        let pdfData = NSMutableData()

        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)

        prepare(forDrawingPages: NSRange(location: 0, length: numberOfPages))

        for i in 0 ..< numberOfPages {
            UIGraphicsBeginPDFPage()
            drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}

private extension CGRect {
    var optionalSizeRect: CGRect? {
        if width <= 0 || height <= 0 { return nil }
        return self
    }
}
