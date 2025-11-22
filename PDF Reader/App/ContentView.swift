import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceBuilder: ServiceBuilder

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                WelcomeView()
                    .padding(.bottom, 40)

                VStack(spacing: 16) {
                    MenuButton(
                        title: "Создать PDF",
                        systemImage: "doc.fill.badge.plus",
                        backgroundColor: .blue,
                        destination: CreateDocumentView()
                            .environmentObject(serviceBuilder)
                    )

                    MenuButton(
                        title: "Сохранённые документы",
                        systemImage: "folder.fill",
                        backgroundColor: .green,
                        destination: SavedDocumentsListView()
                            .environmentObject(serviceBuilder)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)

                Spacer()
            }
            .navigationTitle("PDF Maker")
        }
    }
}

#Preview {
    ContentView()
}
