import SwiftUI

struct NameStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var name = ""

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Spacer()

                    ChloeAvatar(size: 100)

                    Text("What should I call you?")
                        .font(.chloeOnboardingQuestion)
                        .foregroundColor(.chloeTextPrimary)
                        .multilineTextAlignment(.center)

                    TextField("Your name", text: $name)
                        .font(.chloeBodyDefault)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(Spacing.cornerRadiusLarge)
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                                .stroke(Color.chloeBorderWarm, lineWidth: 1)
                        )
                        .padding(.horizontal, Spacing.xxl)
                        .accessibilityLabel("Your name")
                        .onSubmit {
                            guard !name.isBlank else { return }
                            viewModel.preferences.name = name
                            viewModel.nextStep()
                        }

                    Spacer()

                    Button {
                        viewModel.preferences.name = name
                        viewModel.nextStep()
                    } label: {
                        ChloeButtonLabel(title: "Continue", isEnabled: !name.isBlank)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(name.isBlank)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xl)
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

#Preview {
    NameStepView(viewModel: OnboardingViewModel())
}
