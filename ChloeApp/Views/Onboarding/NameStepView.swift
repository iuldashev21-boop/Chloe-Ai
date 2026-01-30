import SwiftUI

struct NameStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var name = ""

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("What should I call you?")
                .font(.chloeTitle)
                .foregroundColor(.chloeTextPrimary)

            TextField("Your name", text: $name)
                .font(.chloeBodyDefault)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.chloeSurface)
                .cornerRadius(Spacing.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                        .stroke(Color.chloeBorder, lineWidth: 1)
                )
                .padding(.horizontal, Spacing.xxl)

            Spacer()

            Button {
                viewModel.preferences.name = name
                viewModel.nextStep()
            } label: {
                Text("Continue")
                    .font(.chloeHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(name.isBlank ? Color.chloeAccentMuted : Color.chloePrimary)
                    .cornerRadius(Spacing.cornerRadius)
            }
            .disabled(name.isBlank)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }
}

#Preview {
    NameStepView(viewModel: OnboardingViewModel())
}
