import SwiftUI

struct NotificationPrimingView: View {
    var displayName: String
    var onEnable: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.chloeBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                ChloeAvatar(size: 80)

                Text("Stay in the Loop")
                    .font(.chloeGreeting)
                    .foregroundColor(.chloePrimary)

                Text("CHLOE WANTS TO CHECK IN ON YOU")
                    .font(.chloeAuthSubheading)
                    .tracking(3)
                    .foregroundColor(.chloeTextSecondary.opacity(0.8))

                Text("Want Chloe to check in on you, \(displayName)? Enable notifications to get random vibe checks and hype messages.")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenHorizontal)

                Button {
                    onEnable()
                } label: {
                    ChloeButtonLabel(title: "Yes, Keep Me Posted")
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, Spacing.screenHorizontal)

                Button("Maybe Later") {
                    onSkip()
                }
                .font(.chloeCaption)
                .foregroundColor(.chloeTextTertiary)

                Spacer()
                    .frame(height: Spacing.xl)
            }
        }
    }
}

#Preview {
    NotificationPrimingView(
        displayName: "Babe",
        onEnable: {},
        onSkip: {}
    )
}
