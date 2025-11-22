import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var completion: ((Bool, [Any]?, Error?) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            completion?(completed, returnedItems, error)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
