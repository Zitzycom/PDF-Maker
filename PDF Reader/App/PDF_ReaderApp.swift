import SwiftUI

@main
struct PDF_ReaderApp: App {
    @StateObject private var serviceBuilder = ServiceBuilder()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataStack.shared.context)
                .environmentObject(serviceBuilder)
        }
    }
}
