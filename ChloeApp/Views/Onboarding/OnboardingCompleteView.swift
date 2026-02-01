import SwiftUI

struct OnboardingCompleteView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 80)

            Text("You're all set!")
                .font(.chloeGreeting)
                .foregroundColor(.chloePrimary)

            Text("I can't wait to get to know you better.\nLet's start your journey together.")
                .font(.chloeBodyLight)
                .foregroundColor(.chloeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()

            Button {
                viewModel.completeOnboarding()
            } label: {
                ChloeButtonLabel(title: "Meet Chloe")
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }
}

#Preview {
    OnboardingCompleteView(viewModel: OnboardingViewModel())
}
