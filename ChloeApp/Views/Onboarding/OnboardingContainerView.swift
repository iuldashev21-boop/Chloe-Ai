import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    /// Total quiz steps (excluding WelcomeIntro at 0 and Complete at 8)
    private let quizStepCount = 7

    private var isWelcomeIntro: Bool { viewModel.currentStep == 0 }
    private var isComplete: Bool { viewModel.currentStep == 8 }

    /// 1-based quiz step index for display (steps 1–7)
    private var displayStep: Int { viewModel.currentStep }

    /// Progress fraction across quiz steps 1–7
    private var quizProgress: CGFloat {
        guard !isWelcomeIntro, !isComplete else { return isComplete ? 1 : 0 }
        return CGFloat(viewModel.currentStep) / CGFloat(quizStepCount)
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Navigation header — hidden on WelcomeIntro & Complete
                if !isWelcomeIntro && !isComplete {
                    headerBar
                    progressBar
                }

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeIntroView(viewModel: viewModel, onContinue: { viewModel.nextStep() }).tag(0)
                    NameStepView(viewModel: viewModel).tag(1)
                    RelationshipStatusView(viewModel: viewModel).tag(2)
                    PrimaryGoalView(viewModel: viewModel).tag(3)
                    CoreDesireView(viewModel: viewModel).tag(4)
                    PainPointView(viewModel: viewModel).tag(5)
                    VibeCheckView(viewModel: viewModel).tag(6)
                    ArchetypeQuizView(viewModel: viewModel).tag(7)
                    OnboardingCompleteView(viewModel: viewModel).tag(8)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.currentStep) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            // Back button
            Button {
                viewModel.previousStep()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.chloeTextPrimary)
            }
            .opacity(viewModel.currentStep > 1 ? 1 : 0)
            .disabled(viewModel.currentStep <= 1)

            Spacer()

            // Step counter
            Text("\(displayStep) of \(quizStepCount)")
                .font(.chloeCaption)
                .foregroundColor(.chloeTextSecondary)

            Spacer()

            // Skip button
            Button {
                viewModel.completeOnboarding()
            } label: {
                Text("Skip")
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextTertiary)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.xs)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.chloeBorder.opacity(0.4))
                    .frame(height: 3)

                Capsule()
                    .fill(Color.chloePrimary)
                    .frame(width: geo.size.width * quizProgress, height: 3)
                    .animation(.easeInOut(duration: 0.3), value: quizProgress)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.xs)
    }
}

#Preview {
    OnboardingContainerView()
}
