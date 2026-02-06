import SwiftUI

/// A reusable empty state view with centered icon and text.
/// Used in Journal, Goals, Vision Board, and History views when there's no content.
struct ChloeEmptyState: View {
    let iconName: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(.chloeTextTertiary)
                .accessibilityHidden(true)

            Text(message)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()

        VStack(spacing: 40) {
            ChloeEmptyState(iconName: "book.closed", message: "Begin writing")
            ChloeEmptyState(iconName: "target", message: "Set your first goal")
            ChloeEmptyState(iconName: "star", message: "Add your first vision")
            ChloeEmptyState(iconName: "clock.arrow.circlepath", message: "No conversations yet")
        }
    }
}
