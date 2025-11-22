import Foundation

enum PDFDocumentMapper {
    static func toModel(_ entity: PDFDocumentEntity) -> PDFDocumentEntityModel? {
        guard let fileURL = entity.fileURL else { return nil }

        return PDFDocumentEntityModel(
            id: entity.id ?? UUID(),
            title: entity.title ?? "",
            fileExtension: entity.fileExtension ?? "pdf",
            createdAt: entity.createdAt ?? Date(),
            thumbnail: entity.thumbnail ?? Data(),
            fileURL: fileURL
        )
    }

    static func fillEntity(_ entity: PDFDocumentEntity, from model: PDFDocumentEntityModel) {
        entity.id = model.id
        entity.title = model.title
        entity.fileExtension = model.fileExtension
        entity.createdAt = model.createdAt
        entity.thumbnail = model.thumbnail
        entity.fileURL = model.fileURL
    }
}
