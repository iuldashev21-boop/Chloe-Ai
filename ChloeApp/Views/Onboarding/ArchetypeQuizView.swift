import SwiftUI

struct ArchetypeQuizView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var q1Answer: ArchetypeChoice? = nil
    @State private var q2Answer: ArchetypeChoice? = nil
    @State private var q3Answer: ArchetypeChoice? = nil
    @State private var q4Answer: ArchetypeChoice? = nil

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    // Q1 options
    private let q1Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Magnetic", "The room goes quiet — effortless."),
        (.b, "Commanding", "One look, and they fall in line."),
        (.c, "Inspiring", "You speak and something shifts inside them."),
        (.d, "Electric", "You walk in — everything changes."),
    ]

    // Q2 options
    private let q2Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Warmth", "They let their guard down around you."),
        (.b, "Intuition", "You know before they say a word."),
        (.c, "Drive", "Nothing stands between you and the vision."),
        (.d, "Mystery", "They can't stop wondering about you."),
    ]

    // Q3 options
    private let q3Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Reflecting", "Stillness, silence, pages of truth."),
        (.b, "Moving", "Sweat, motion, letting the body lead."),
        (.c, "Creating", "Pouring the chaos into something beautiful."),
        (.d, "Escaping", "New air, new streets, disappearing for a while."),
    ]

    // Q4 options
    private let q4Options: [(choice: ArchetypeChoice, title: String, description: String)] = [
        (.a, "Sensuality", "A slow glance that says everything."),
        (.b, "Standards", "The quiet power of 'I don't settle.'"),
        (.c, "Depth", "You see through him — and he craves it."),
        (.d, "Wildness", "Unpredictable, untamed, utterly alive."),
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

            // Space for container-level guide orb
            Spacer().frame(height: 80)

            questionView(
                question: questions[viewModel.quizPage],
                options: optionsForPage(viewModel.quizPage),
                selected: answerForPage(viewModel.quizPage),
                onSelect: { setAnswer($0, for: viewModel.quizPage) }
            )

            Spacer()

            Button {
                if viewModel.quizPage < 3 {
                    withAnimation(.easeInOut) {
                        viewModel.quizPage += 1
                    }
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
                    isEnabled: answerForPage(viewModel.quizPage) != nil
                )
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(viewModel.quizPage < 3 ? "Continue to next question" : "See results")
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
