import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    /// Total quiz steps: Name (1) + Quiz Q1-Q4 (2-5) = 5
    private let quizStepCount = 5

    private var isWelcomeIntro: Bool { viewModel.currentStep == 0 }
    private var isComplete: Bool { viewModel.currentStep == 3 }

    /// 1-based display step: step 1 → 1, step 2 (quiz) → 2 + quizPage
    private var displayStep: Int {
        switch viewModel.currentStep {
        case 1: return 1
        case 2: return 2 + viewModel.quizPage
        default: return viewModel.currentStep
        }
    }

    /// Progress fraction across all 5 quiz steps
    private var quizProgress: CGFloat {
        guard !isWelcomeIntro, !isComplete else { return isComplete ? 1 : 0 }
        return CGFloat(displayStep) / CGFloat(quizStepCount)
    }

    // Orb state
    @State private var orbAppeared = false
    @State private var orbNamePulse: CGFloat = 1.0
    @State private var orbGlowRadius: CGFloat = 10

    var body: some View {
        ZStack {
            GradientBackground()

            EtherealDustParticles()
                .opacity(0.05)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header — hidden on WelcomeIntro & Complete
                if !isWelcomeIntro && !isComplete {
                    headerBar
                    progressBar
                }

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeIntroView(viewModel: viewModel, onContinue: {
                        viewModel.nextStep()
                    }).tag(0)
                    NameStepView(viewModel: viewModel).tag(1)
                    ArchetypeQuizView(viewModel: viewModel).tag(2)
                    OnboardingCompleteView(viewModel: viewModel).tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }

            // MARK: - Persistent Guide Orb (overlay)
            GeometryReader { geo in
                let topY = geo.size.height * 0.14

                ChloeAvatar(size: 80)
                    .scaleEffect((orbAppeared ? 0.8 : 0.5) * orbNamePulse)
                    .opacity(orbAppeared ? 1 : 0)
                    .shadow(color: Color(hex: "#B76E79").opacity(0.4), radius: orbGlowRadius)
                    .position(
                        x: geo.size.width / 2,
                        y: topY
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: orbAppeared)
                    .animation(.easeOut(duration: 0.15), value: orbNamePulse)
                    .animation(.easeInOut(duration: 0.3), value: orbGlowRadius)
                    .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.currentStep) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                orbAppeared = true
            }
        }
        .onChange(of: viewModel.nameText) {
            // Pulse the orb on each keystroke
            orbNamePulse = 1.08
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                orbNamePulse = 1.0
            }
        }
        .onChange(of: viewModel.quizPage) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                orbGlowRadius = 30
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    orbGlowRadius = 10
                }
            }
        }
        .onChange(of: viewModel.currentStep) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                orbGlowRadius = 30
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    orbGlowRadius = 10
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            // Back button
            Button {
                if viewModel.currentStep == 2 && viewModel.quizPage > 0 {
                    withAnimation(.easeInOut) { viewModel.quizPage -= 1 }
                } else {
                    viewModel.previousStep()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.chloeTextPrimary)
            }
            .accessibilityLabel("Go back")
            .opacity(displayStep > 1 ? 1 : 0)
            .disabled(displayStep <= 1)

            Spacer()

            // Step counter
            Text("\(displayStep) of \(quizStepCount)")
                .font(.chloeCaption)
                .foregroundColor(.chloeTextSecondary)
                .accessibilityLabel("Step \(displayStep) of \(quizStepCount)")

            Spacer()

            // Skip button
            Button {
                viewModel.completeOnboarding()
            } label: {
                Text("Skip")
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextTertiary)
            }
            .accessibilityLabel("Skip onboarding")
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
        .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingContainerView()
}
