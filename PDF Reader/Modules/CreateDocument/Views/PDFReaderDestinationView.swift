import SwiftUICore

struct PDFReaderDestinationView: View {
    let document: PDFDocumentEntityModel?

    var body: some View {
        if let doc = document {
            PDFReaderView(document: doc)
        } else {
            EmptyView()
        }
    }
}
