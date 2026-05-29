import SwiftUI

// Disables the iOS interactive pop gesture on the current screen.
// Use .navigationPopGestureDisabled(true) on any view inside a NavigationStack.
private struct PopGestureController: UIViewControllerRepresentable {
    let disabled: Bool

    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = !disabled
        }
    }
}

extension View {
    func navigationPopGestureDisabled(_ disabled: Bool = true) -> some View {
        background(PopGestureController(disabled: disabled))
    }
}
