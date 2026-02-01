import SwiftUI

struct ArchetypeQuizView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var quizPage = 0
    @State private var q1Answer: ArchetypeChoice? = nil
    @State private var q2Answer: ArchetypeChoice? = nil
    @State private var q3Answer: ArchetypeChoice? = nil
    @State private var q4Answer: ArchetypeChoice? = nil

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    // Q1 options
    private let q1Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Magnetic", "People are drawn to your energy"),
        (.b, "Commanding", "You lead with quiet authority"),
        (.c, "Inspiring", "You light a fire in others"),
        (.d, "Electric", "Your presence shifts the room"),
    ]

    // Q2 options
    private let q2Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Warmth", "You make everyone feel safe"),
        (.b, "Intuition", "You sense what others can't"),
        (.c, "Drive", "Relentless focus and ambition"),
        (.d, "Mystery", "An allure that keeps them curious"),
    ]

    // Q3 options
    private let q3Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Reflecting", "Journaling, silence, inner work"),
        (.b, "Moving", "Gym, walks, physical energy release"),
        (.c, "Creating", "Music, art, pouring it into beauty"),
        (.d, "Escaping", "Spontaneity, new places, breaking routine"),
    ]

    // Q4 options
    private let q4Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Sensuality", "Your softness and magnetic presence"),
        (.b, "Standards", "Your poise and unshakeable boundaries"),
        (.c, "Depth", "Your mind and emotional intelligence"),
        (.d, "Wildness", "Your unpredictability and fearless honesty"),
    ]

    private let questions = [
        "When you imagine your most powerful self, she is...",
        "Your secret weapon is...",
        "When life gets heavy, you reset by...",
        "In your dream relationship, he's drawn to your...",
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 100)

            questionView(
                question: questions[quizPage],
                options: optionsForPage(quizPage),
                selected: answerForPage(quizPage),
                onSelect: { setAnswer($0, for: quizPage) }
            )

            Spacer()

            Button {
                if quizPage < 3 {
                    withAnimation(.easeInOut) { quizPage += 1 }
                } else {
                    viewModel.preferences.archetypeAnswers = ArchetypeAnswers(
                        energy: q1Answer,
                        strength: q2Answer,
                        recharge: q3Answer,
                        allure: q4Answer
                    )
                    viewModel.nextStep()
                }
            } label: {
                ChloeButtonLabel(
                    title: "Continue",
                    isEnabled: answerForPage(quizPage) != nil
                )
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Helpers

    private func optionsForPage(_ page: Int) -> [(choice: ArchetypeChoice, title: String, description: String)] {
        switch page {
        case 0: return q1Options
        case 1: return q2Options
        case 2: return q3Options
        case 3: return q4Options
        default: return q1Options
        }
    }

    private func answerForPage(_ page: Int) -> ArchetypeChoice? {
        switch page {
        case 0: return q1Answer
        case 1: return q2Answer
        case 2: return q3Answer
        case 3: return q4Answer
        default: return nil
        }
    }

    private func setAnswer(_ choice: ArchetypeChoice, for page: Int) {
        switch page {
        case 0: q1Answer = choice
        case 1: q2Answer = choice
        case 2: q3Answer = choice
        case 3: q4Answer = choice
        default: break
        }
    }

    // MARK: - Question View

    @ViewBuilder
    private func questionView(
        question: String,
        options: [(choice: ArchetypeChoice, title: String, description: String)],
        selected: ArchetypeChoice?,
        onSelect: @escaping (ArchetypeChoice) -> Void
    ) -> some View {
        Text(question)
            .font(.chloeOnboardingQuestion)
            .foregroundColor(.chloeTextPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.screenHorizontal)

        LazyVGrid(columns: columns, spacing: Spacing.xs) {
            ForEach(options, id: \.choice) { item in
                OnboardingCard(
                    title: item.title,
                    description: item.description,
                    isSelected: selected == item.choice,
                    action: { onSelect(item.choice) }
                )
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

#Preview {
    ArchetypeQuizView(viewModel: OnboardingViewModel())
}
