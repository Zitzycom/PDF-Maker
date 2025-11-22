import CoreData

protocol DocumentStorageProtocol {
    func save(_ model: PDFDocumentEntityModel) async
    func fetchAll() async -> [PDFDocumentEntityModel]
    func delete(id: UUID) async
    func getAllDocumentsTitles() async -> [String]
}

final class DocumentStorageService: DocumentStorageProtocol {
    private let context = CoreDataStack.shared.context

    func save(_ model: PDFDocumentEntityModel) async {
        await context.perform {
            let entity = PDFDocumentEntity(context: self.context)
            PDFDocumentMapper.fillEntity(entity, from: model)
            do {
                try self.context.save()
            } catch {
                print("CoreData save error: \(error)")
            }
        }
    }

    func fetchAll() async -> [PDFDocumentEntityModel] {
        await context.perform {
            let request: NSFetchRequest<PDFDocumentEntity> = PDFDocumentEntity.fetchRequest()
            do {
                let entities = try self.context.fetch(request)
                return entities.compactMap { PDFDocumentMapper.toModel($0) }
            } catch {
                print("CoreData fetch error: \(error)")
                return []
            }
        }
    }

    func delete(id: UUID) async {
        await context.perform {
            let request: NSFetchRequest<PDFDocumentEntity> = PDFDocumentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            do {
                if let result = try self.context.fetch(request).first {
                    self.context.delete(result)
                    try self.context.save()
                }
            } catch {
                print("CoreData delete error: \(error)")
            }
        }
    }

    func getAllDocumentsTitles() async -> [String] {
        await context.perform {
            let request: NSFetchRequest<PDFDocumentEntity> = PDFDocumentEntity.fetchRequest()
            do {
                let entities = try self.context.fetch(request)
                return entities.compactMap { $0.title }
            } catch {
                print("CoreData fetch titles error: \(error)")
                return []
            }
        }
    }
}
