import SwiftUI

struct NameStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Spacer()

                    // Space for container-level guide orb
                    Spacer().frame(height: 80)

                    Text("What shall I call you, beautiful?")
                        .chloeEditorialHeading()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .background(
                            RadialGradient(
                                colors: [Color(hex: "#FAD6A5").opacity(0.05), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                            .blur(radius: 30)
                        )

                    // Single glowing line input
                    TextField("", text: $viewModel.nameText, prompt:
                        Text("Your name")
                            .font(.system(size: 20, weight: .light).italic())
                            .foregroundColor(.chloeRosewood.opacity(0.6))
                    )
                    .font(.custom(ChloeFont.heroBoldItalic, size: 24))
                    .foregroundColor(.chloeTextPrimary)
                    .multilineTextAlignment(.center)
                    .focused($nameFieldFocused)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.clear)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color(hex: "#B76E79").opacity(nameFieldFocused ? 0.9 : 0.3))
                            .frame(height: nameFieldFocused ? 1 : 0.5)
                            .shadow(color: Color(hex: "#B76E79").opacity(nameFieldFocused ? 0.5 : 0), radius: 6)
                            .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .accessibilityLabel("Your name")
                    .onSubmit {
                        guard !viewModel.nameText.isBlank else { return }
                        viewModel.preferences.name = viewModel.nameText
                        viewModel.nextStep()
                    }

                    Spacer()

                    Button {
                        viewModel.preferences.name = viewModel.nameText
                        viewModel.nextStep()
                    } label: {
                        ChloeButtonLabel(title: "Continue", isEnabled: !viewModel.nameText.isBlank)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(viewModel.nameText.isBlank)
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
