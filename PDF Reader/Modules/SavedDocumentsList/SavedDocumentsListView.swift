import SwiftUI

struct SavedDocumentsListView: View {
    @StateObject private var viewModel = SavedDocumentsListViewModel()

    var body: some View {
        List {
            ForEach(viewModel.documents) { document in
                NavigationLink(destination: PDFReaderView(document: document)) {
                    SavedDocumentCellView(document: document)
                }
                .contextMenu {
                    Button("Поделиться") {
                        viewModel.share(document)
                    }
                    Button("Удалить", role: .destructive) {
                        viewModel.deleteDocument(id: document.id)
                    }
                    Button("Объединить с...") {
                        viewModel.startMerge(document)
                    }
                }
            }
        }
        .navigationTitle("Документы")
        .onAppear {
            Task { await viewModel.loadDocuments() }
        }
        .sheet(isPresented: $viewModel.showingMergeSheet) {
            mergeSheet
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ActivityView(activityItems: viewModel.itemsToShare)
        }
    }

    private var mergeSheet: some View {
        VStack(spacing: 20) {
            Text("Выберите второй документ для объединения")
                .font(.headline)

            List(viewModel.availableDocumentsForMerge) { document in
                Button(document.title) {
                    viewModel.selectSecondDocument(document)
                }
            }

            if viewModel.mergeSecondDocument != nil {
                TextField("Название нового документа", text: $viewModel.newDocumentTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Создать объединённый документ") {
                    viewModel.createMergedDocument()
                }
                .padding()
            }

            Button("Отмена") {
                viewModel.cancelMerge()
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    SavedDocumentsListView()
}
