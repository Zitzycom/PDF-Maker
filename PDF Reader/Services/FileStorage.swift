import Foundation

final class FileStorage {
    static let shared = FileStorage()
    
    private init() {}
    
    func save(data: Data, name: String) -> URL? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
        
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
