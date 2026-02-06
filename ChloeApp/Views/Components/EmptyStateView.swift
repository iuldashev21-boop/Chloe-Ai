import SwiftUI

/// A polished empty state view with icon, title, subtitle, and optional action button.
/// Used when screens have no data to display — provides friendly guidance to users.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .thin))
                .foregroundColor(.chloeTextSecondary)
                .padding(.bottom, Spacing.xxs)
                .accessibilityHidden(true)

            Text(title)
                .font(.chloeHeadline)
                .foregroundColor(.chloeTextPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.chloeCaption)
                .foregroundColor(.chloeTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Spacing.xl)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.chloeBodyDefault)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Color.chloePrimary)
                        )
                }
                .padding(.top, Spacing.xs)
                .accessibilityLabel(actionTitle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()

        EmptyStateView(
            icon: "book",
            title: "No journal entries yet",
            subtitle: "Tap + to start writing about your day"
        )
    }
}

#Preview("With Action") {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()

        EmptyStateView(
            icon: "target",
            title: "No goals set yet",
            subtitle: "Set your first goal to start tracking progress",
            actionTitle: "Add Goal",
            action: { }
        )
    }
}
