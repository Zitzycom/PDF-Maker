import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    @Binding var document: PDFDocument?
    private let pdfView = PDFView()

    func makeUIView(context: Context) -> PDFView {
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.backgroundColor = UIColor.systemBackground
        if let doc = document { pdfView.document = doc }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
        }
    }
}
