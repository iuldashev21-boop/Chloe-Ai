import SwiftUI

/// A reusable floating action button with glassmorphic styling.
/// Used for "Add" actions in Journal, Goals, and Vision Board views.
struct ChloeFloatingActionButton: View {
    let action: () -> Void
    let accessibilityLabel: String
    let iconName: String

    init(
        iconName: String = "plus",
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.chloePrimary)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: Color.chloeRosewood.opacity(0.12),
                    radius: 8,
                    x: 0,
                    y: 3
                )
        }
        .accessibilityLabel(accessibilityLabel)
        .padding(.trailing, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.lg)
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color.chloeBackground.ignoresSafeArea()
        ChloeFloatingActionButton(accessibilityLabel: "Add item") {
            print("Tapped!")
        }
    }
}
