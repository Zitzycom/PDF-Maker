import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Добро пожаловать")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                .minimumScaleFactor(0.5)
                .lineLimit(nil)

            Text("""
Это приложение позволяет:
• Добавлять фотографии и файлы из галереи или файловой системы
• Конвертировать их в PDF-документы
• Просматривать PDF прямо в приложении
• Удалять ненужные страницы из документа
• Сохранять и делиться готовыми PDF
""")
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 24)
            .minimumScaleFactor(0.5)
            .lineLimit(nil)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    WelcomeView()
}
