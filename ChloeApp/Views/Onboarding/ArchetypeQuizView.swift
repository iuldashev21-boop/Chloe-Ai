import SwiftUI

struct ArchetypeQuizView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("Archetype Quiz")
                .font(.chloeTitle)
                .foregroundColor(.chloeTextPrimary)

            Text("Answer a few questions to discover your feminine archetype")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            // TODO: Implement quiz questions
            Text("Coming soon")
                .font(.chloeCaption)
                .foregroundColor(.chloeTextTertiary)

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Continue")
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
    ArchetypeQuizView(viewModel: OnboardingViewModel())
}
