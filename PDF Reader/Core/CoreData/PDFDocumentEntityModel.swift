import Foundation

struct PDFDocumentEntityModel: Identifiable {
    let id: UUID
    var title: String
    var fileExtension: String
    var createdAt: Date
    var thumbnail: Data
    var fileURL: URL
}
