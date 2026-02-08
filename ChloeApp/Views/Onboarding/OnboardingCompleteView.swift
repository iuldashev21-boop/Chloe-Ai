import SwiftUI
import ConfettiSwiftUI

struct OnboardingCompleteView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var confettiCounter = 0

    var body: some View {
        let archetype: UserArchetype? = {
            guard let answers = viewModel.preferences.archetypeAnswers else { return nil }
            return ArchetypeService.shared.classify(answers: answers)
        }()

        VStack(spacing: Spacing.lg) {
            Spacer()

            // Space for container-level guide orb
            Spacer().frame(height: 80)

            Text("You're all set!")
                .font(.chloeGreeting)
                .foregroundColor(.chloePrimary)

            if let archetype {
                VStack(spacing: Spacing.sm) {
                    Text("YOUR ARCHETYPE")
                        .font(.chloeAuthSubheading)
                        .tracking(3)
                        .foregroundColor(.chloeTextSecondary.opacity(0.8))

                    Text(archetype.label)
                        .font(.custom(ChloeFont.headerDisplay, size: 28))
                        .foregroundColor(.chloePrimary)
                }
            }

            Text("I can't wait to get to know you better.\nLet's start your journey together.".uppercased())
                .font(.chloeAuthSubheading)
                .tracking(3)
                .foregroundColor(.chloeTextSecondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()

            Button {
                viewModel.completeOnboarding()
            } label: {
                ChloeButtonLabel(title: "Meet Chloe")
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Meet Chloe")
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
        .confettiCannon(counter: $confettiCounter, num: 50,
                         colors: [.chloePrimary, .chloeAccent, .chloeEtherealGold],
                         rainHeight: 600, radius: 400)
        .onAppear {
            // Fire if already on this step (e.g. direct navigation)
            if viewModel.currentStep == 3 {
                fireConfetti()
            }
        }
        .onChange(of: viewModel.currentStep) { _, newStep in
            if newStep == 3 {
                fireConfetti()
            }
        }
    }

    private func fireConfetti() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            confettiCounter += 1
        }
    }
}

#Preview {
    OnboardingCompleteView(viewModel: OnboardingViewModel())
}
