import SwiftUI

struct OnboardingCompleteView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 80)

            Text("You're all set!")
                .font(.chloeLargeTitle)
                .foregroundColor(.chloePrimary)

            Text("I can't wait to get to know you better.\nLet's start your journey together.")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()

            Button {
                viewModel.completeOnboarding()
            } label: {
                Text("Meet Chloe")
                    .font(.chloeHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.chloePrimary)
                    .cornerRadius(Spacing.cornerRadius)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }
}

#Preview {
    OnboardingCompleteView(viewModel: OnboardingViewModel())
}
