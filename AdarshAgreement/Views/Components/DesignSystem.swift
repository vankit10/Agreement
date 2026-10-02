import SwiftUI
import UIKit

enum AgreementTheme {
    static let accent = Color(red: 0.16, green: 0.40, blue: 0.67)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let border = Color.primary.opacity(0.08)
    static let spacing: CGFloat = 12
    static let margin: CGFloat = 20
    static let radius: CGFloat = 16
}

struct AgreementCard: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .background(AgreementTheme.surface, in: RoundedRectangle(cornerRadius: AgreementTheme.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AgreementTheme.radius, style: .continuous).stroke(AgreementTheme.border, lineWidth: 1))
            .shadow(color: .black.opacity(scheme == .dark ? 0.18 : 0.05), radius: 8, x: 0, y: 3)
    }
}

struct AgreementButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    var kind: Kind = .primary
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .foregroundStyle(kind == .primary ? Color.white : AgreementTheme.accent)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(kind == .primary ? AgreementTheme.accent : AgreementTheme.accent.opacity(0.09))
            }
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(kind == .primary ? Color.clear : AgreementTheme.accent.opacity(0.12), lineWidth: 1))
            .shadow(color: kind == .primary ? AgreementTheme.accent.opacity(enabled ? 0.18 : 0) : .clear, radius: 7, x: 0, y: 3)
            .opacity(enabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
            .sensoryFeedback(.selection, trigger: configuration.isPressed)
    }
}

struct AgreementFormStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, design: .rounded))
            .textFieldStyle(AgreementInputStyle())
            .environment(\.defaultMinListRowHeight, 44)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listSectionSpacing(12)
            .scrollContentBackground(.hidden)
            .background(AgreementTheme.canvas)
            .tint(AgreementTheme.accent)
    }
}

struct AgreementInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(.subheadline, design: .rounded))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(AgreementTheme.canvas.opacity(0.8), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AgreementTheme.border, lineWidth: 1))
    }
}

struct CompactToggle: View {
    let title: String
    @Binding var isOn: Bool
    var showsTitle = true
    var body: some View {
        HStack(spacing: 10) {
            Toggle(title, isOn: $isOn)
                .toggleStyle(.switch).labelsHidden().fixedSize()
                .scaleEffect(0.60)
                .frame(width: 40, height: 44)
                .accessibilityLabel(title)
            if showsTitle {
                Text(LocalizedStringKey(title)).font(.system(.subheadline, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Dismisses the active keyboard when the user taps anywhere other than a text input.
/// The recognizer does not cancel the original tap, so switches and buttons continue
/// to respond normally.
struct KeyboardDismissOnOutsideTap: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIView { UIView(frame: .zero) }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async { context.coordinator.install(in: view.window) }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.remove()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var recognizer: UITapGestureRecognizer?

        func install(in window: UIWindow?) {
            guard let window, recognizer?.view !== window else { return }
            remove()
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            recognizer = tap
        }

        func remove() {
            recognizer?.view?.removeGestureRecognizer(recognizer!)
            recognizer = nil
        }

        @objc private func dismissKeyboard() {
            recognizer?.view?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView { return false }
                view = current.superview
            }
            return true
        }
    }
}

extension View {
    func agreementCard() -> some View { modifier(AgreementCard()) }
    func agreementForm() -> some View { modifier(AgreementFormStyle()) }
}
