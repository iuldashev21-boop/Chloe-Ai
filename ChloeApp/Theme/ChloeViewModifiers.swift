import SwiftUI

// MARK: - Chloe Card Style ViewModifier

/// Glassmorphic card style with ultraThinMaterial background, white border, and rosewood shadow.
/// Used throughout the app for consistent card appearance.
struct ChloeCardStyleModifier: ViewModifier {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 28) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: Color.chloeRosewood.opacity(0.12),
                radius: 16,
                x: 0,
                y: 6
            )
    }
}

extension View {
    /// Applies the standard Chloe glassmorphic card style.
    /// - Parameter cornerRadius: Corner radius for the card. Defaults to 28.
    /// - Returns: A view with the glassmorphic card style applied.
    func chloeCardStyle(cornerRadius: CGFloat = 28) -> some View {
        modifier(ChloeCardStyleModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Chloe Spring Animation

extension Animation {
    /// Standard spring animation used for sanctuary transitions and chat activation.
    /// Response: 0.5, Damping Fraction: 0.85
    static let chloeSpring = Animation.spring(response: 0.5, dampingFraction: 0.85)
}
