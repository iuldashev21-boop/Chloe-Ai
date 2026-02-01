import SwiftUI

struct ArchetypeQuizView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var quizPage = 0
    @State private var q1Answer: ArchetypeChoice? = nil
    @State private var q2Answer: ArchetypeChoice? = nil

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

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 40)

            if quizPage == 0 {
                questionView(
                    question: "When you imagine your most powerful self, she is...",
                    options: q1Options,
                    selected: q1Answer,
                    onSelect: { q1Answer = $0 }
                )
            } else {
                questionView(
                    question: "Your secret weapon is...",
                    options: q2Options,
                    selected: q2Answer,
                    onSelect: { q2Answer = $0 }
                )
            }

            Spacer()

            Button {
                if quizPage == 0 {
                    withAnimation(.easeInOut) { quizPage = 1 }
                } else {
                    viewModel.preferences.archetypeAnswers = ArchetypeAnswers(
                        energy: q1Answer,
                        strength: q2Answer
                    )
                    viewModel.nextStep()
                }
            } label: {
                ChloeButtonLabel(
                    title: "Continue",
                    isEnabled: quizPage == 0 ? q1Answer != nil : q2Answer != nil
                )
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
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
