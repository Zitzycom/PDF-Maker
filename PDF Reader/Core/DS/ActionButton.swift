import SwiftUI

struct ActionButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.headline)
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
    ActionButton(
        title: "Create PDF",
        systemImage: "doc.fill.badge.plus",
        backgroundColor: .blue
    ) {
        print("Action")
    }
}
