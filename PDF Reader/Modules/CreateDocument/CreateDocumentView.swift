import SwiftUI

struct CreateDocumentView: View {
    @EnvironmentObject var serviceBuilder: ServiceBuilder
    @StateObject private var viewModel = CreateDocumentViewModel()

    var body: some View {
        VStack(spacing: 16) {
            attachmentsGrid
            bottomActions
        }
        .navigationTitle("Создание PDF")
        .onReceive(viewModel.$previewDocument) { doc in
            if doc != nil { viewModel.navigateToPDF = true }
        }
        .confirmationDialog("Выберите тип документа", isPresented: $viewModel.showPickerTypeDialog) {
            Button("Фото") { viewModel.showImagePicker = true }
            Button("Файл") { viewModel.showDocumentPicker = true }
            Button("Отмена", role: .cancel) {}
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(images: viewModel.imagesBinding)
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            UIDocumentPickerViewControllerWrapper { urls in
                viewModel.addFiles(urls: urls)
                viewModel.showDocumentPicker = false
            }
        }
        .sheet(isPresented: $viewModel.isPresentingActivity, onDismiss: viewModel.cleanupShare) {
            if let shareURL = viewModel.shareURL {
                ActivityView(activityItems: [shareURL], completion: { _, _, _ in })
            }
        }
        .background(
            NavigationLink(
                destination: PDFReaderDestinationView(document: viewModel.previewDocument),
                isActive: $viewModel.navigateToPDF,
                label: { EmptyView() }
            )
        )
        .padding(.bottom, 16)
    }

    private var attachmentsGrid: some View {
        Group {
            if viewModel.attachments.isEmpty {
                addFileButton.padding(.horizontal, 16)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                        ForEach(Array(viewModel.attachments.enumerated()), id: \.offset) { index, attachment in
                            ZStack(alignment: .topTrailing) {
                                AttachmentView(attachment: attachment)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)

                                Button(action: { viewModel.removeAttachment(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(RoundedRectangle(cornerRadius: 16).stroke(.gray))
                .padding(.horizontal, 16)
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 16) {
            if !viewModel.attachments.isEmpty {
                addFileButton.padding(.horizontal, 16)
            }

            ActionButton(
                title: "Создать PDF",
                systemImage: "doc.fill.badge.plus",
                backgroundColor: .blue,
                action: viewModel.createPreviewAsync
            )
            .padding(.horizontal, 16)

            if viewModel.previewDocument != nil {
                HStack(spacing: 16) {
                    ActionButton(
                        title: "Сохранить",
                        systemImage: "tray.and.arrow.down.fill",
                        backgroundColor: .green,
                        action: viewModel.savePreviewAsync
                    )
                    ActionButton(
                        title: "Поделиться",
                        systemImage: "square.and.arrow.up.fill",
                        backgroundColor: .orange,
                        action: viewModel.sharePreview
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var addFileButton: some View {
        Button(action: { viewModel.showPickerTypeDialog = true }) {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 80, maxHeight: 80)
                    .foregroundColor(.gray)
                Text("Добавьте файлы")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).stroke(.gray))
        }
    }
}

#Preview {
    CreateDocumentView()
}
