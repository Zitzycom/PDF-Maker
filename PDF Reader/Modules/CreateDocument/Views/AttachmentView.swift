import SwiftUI

struct AttachmentView: View {
    let attachment: CreateDocumentViewModel.Attachment

    var body: some View {
        switch attachment {
        case .image(let img):
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .clipped()
        case .pdf:
            VStack {
                Image(systemName: "doc.richtext")
                    .font(.largeTitle)
                Text("PDF")
                    .font(.caption)
            }
        case .other(let url):
            VStack {
                Image(systemName: "doc")
                    .font(.largeTitle)
                Text(url.lastPathComponent)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
    }
}
