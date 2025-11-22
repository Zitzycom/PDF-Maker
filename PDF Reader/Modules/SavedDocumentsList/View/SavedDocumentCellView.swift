import SwiftUI

struct SavedDocumentCellView: View {
    let document: PDFDocumentEntityModel

    var body: some View {
        HStack {
            if let image = UIImage(data: document.thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading) {
                Text(document.title)
                    .font(.headline)

                Text(".\(document.fileExtension)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(dateString(document.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
