import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: viewModel.progress)
                    .tint(.chloePrimary)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.sm)

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    NameStepView(viewModel: viewModel).tag(0)
                    RelationshipStatusView(viewModel: viewModel).tag(1)
                    PrimaryGoalView(viewModel: viewModel).tag(2)
                    CoreDesireView(viewModel: viewModel).tag(3)
                    PainPointView(viewModel: viewModel).tag(4)
                    VibeCheckView(viewModel: viewModel).tag(5)
                    ArchetypeQuizView(viewModel: viewModel).tag(6)
                    OnboardingCompleteView(viewModel: viewModel).tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    OnboardingContainerView()
}
