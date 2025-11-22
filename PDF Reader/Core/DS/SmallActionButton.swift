import SwiftUI

struct SmallActionButton: View {
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(backgroundColor)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }
}

#Preview {
    SmallActionButton(
        title: "Создать PDF с очень длинным названием",
        backgroundColor: .blue
    ) {
        print("Action")
    }
}
