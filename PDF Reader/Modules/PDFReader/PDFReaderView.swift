import SwiftUI

struct PDFReaderView: View {
    @StateObject private var viewModel: PDFReaderViewModel

    init(document: PDFDocumentEntityModel) {
//        _viewModel = StateObject(wrappedValue: PDFReaderViewModel(document: document, storage: <#any DocumentStorageProtocol#>))
        _viewModel = StateObject(wrappedValue: PDFReaderViewModel(document: document))
    }

    var body: some View {
        VStack(spacing: 0) {
            PDFKitView(document: $viewModel.pdfDocument)
                .frame(maxHeight: .infinity)

            thumbnailsStrip
                .frame(height: 120)
                .background(Color(UIColor.systemBackground))
                .overlay(Divider(), alignment: .top)

            if viewModel.isSelecting {
                bottomSelectionToolbar
                    .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle(viewModel.documentModel.title)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { topMenu } }
        .onAppear { viewModel.reloadIfNeeded() }
        .sheet(isPresented: $viewModel.showAddTextSheet, content: { addTextSheet })
        .alert("Имя нового документа", isPresented: $viewModel.showMergeNameAlert) { mergeNameAlertActions } message: { EmptyView() }
    }

    private var topMenu: some View {
        Menu {
            Button(viewModel.isSelecting ? "Отменить выбор" : "Выбрать") { viewModel.toggleSelectionMode() }
            Button("Добавить новую страницу") {
                viewModel.newTextForPage = ""
                viewModel.showAddTextSheet = true
            }
            Button("Сохранить изменения") { Task { await viewModel.saveChangesAsync() } }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
        }
    }

    private var thumbnailsStrip: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 8) {
                ForEach(0..<max(0, viewModel.pageCount), id: \.self) { index in
                    thumbnailItem(index: index)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func thumbnailItem(index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                if viewModel.isSelecting {
                    viewModel.toggleSelectPage(index)
                } else {
                    viewModel.goToPage(index)
                }
            }) {
                VStack(spacing: 4) {
                    if let thumb = viewModel.thumbnail(at: index) {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 84)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(viewModel.currentPageIndex == index ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 70, height: 84)
                            .cornerRadius(6)
                    }

                    Text("\(index + 1)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if viewModel.isSelecting {
                Button {
                    viewModel.toggleSelectPage(index)
                } label: {
                    Image(systemName: viewModel.selectedPages.contains(index) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.selectedPages.contains(index) ? .blue : .white)
                        .background(Circle().fill(Color.black.opacity(0.35)).frame(width: 32, height: 32))
                }
                .padding(6)
            }
        }
        .id("\(viewModel.revision.uuidString)-\(index)")
    }

    private var bottomSelectionToolbar: some View {
        HStack(spacing: 12) {
            SmallActionButton(title: "Удалить", backgroundColor: .red) {
                Task {
                    await viewModel.deleteSelectedPagesAsync()
                    viewModel.toggleSelectionMode()
                }
            }
            .disabled(viewModel.selectedPages.isEmpty)

            SmallActionButton(title: "Объединить в новый", backgroundColor: .blue) {
                viewModel.showMergeNameAlert = true
            }
            .disabled(viewModel.selectedPages.isEmpty)

            SmallActionButton(title: "Сохранить", backgroundColor: .green) {
                Task { await viewModel.saveChangesAsync() }
                viewModel.toggleSelectionMode()
            }
            .disabled(viewModel.selectedPages.isEmpty)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }
    
    private var addTextSheet: some View {
        NavigationView {
            VStack {
                TextEditor(text: $viewModel.newTextForPage)
                    .padding()
            }
            .navigationTitle("Текст для страницы")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        if !viewModel.newTextForPage.isEmpty {
                            viewModel.addTextPageAsync(text: viewModel.newTextForPage)
                            viewModel.newTextForPage = ""
                        }
                        viewModel.showAddTextSheet = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        viewModel.newTextForPage = ""
                        viewModel.showAddTextSheet = false
                    }
                }
            }
        }
    }

    private var mergeNameAlertActions: some View {
        VStack {
            TextField("Имя", text: $viewModel.mergeDocumentName)
            HStack {
                ActionButton(title: "Создать", systemImage: "doc.fill.badge.plus", backgroundColor: .green) {
                    let name = viewModel.mergeDocumentName.isEmpty ? "Merged \(Int.random(in: 1000...9999))" : viewModel.mergeDocumentName
                    Task { await viewModel.mergeSelectedPagesAsync(name: name) }
                    viewModel.mergeDocumentName = ""
                    viewModel.toggleSelectionMode()
                }

                ActionButton(title: "Отмена", systemImage: "xmark", backgroundColor: .secondary) {
                    viewModel.mergeDocumentName = ""
                }
            }
            .padding()
        }
        .padding(.vertical)
    }
}
