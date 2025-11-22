import SwiftUI

struct MenuButton<Destination: View>: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .minimumScaleFactor(0.5)

            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}

#Preview {
    MenuButton(
        title: "Create PDF",
        systemImage: "doc.fill.badge.plus",
        backgroundColor: .blue,
        destination: CreateDocumentView()
    )
}
