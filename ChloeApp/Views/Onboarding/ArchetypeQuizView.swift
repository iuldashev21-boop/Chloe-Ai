import SwiftUI

struct ArchetypeQuizView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var q1Answer: ArchetypeChoice? = nil
    @State private var q2Answer: ArchetypeChoice? = nil
    @State private var q3Answer: ArchetypeChoice? = nil
    @State private var q4Answer: ArchetypeChoice? = nil

    @State private var wordRevealID = UUID()
    @State private var cardsAppeared = false

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
        .onChange(of: viewModel.quizPage) { _, _ in
            cardsAppeared = false
            wordRevealID = UUID()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    cardsAppeared = true
                }
            }
        }
        .onAppear {
            cardsAppeared = true
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        StaggeredWordReveal(text: question)
            .id(wordRevealID)
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

        LazyVGrid(columns: columns, spacing: Spacing.xs) {
            ForEach(Array(options.enumerated()), id: \.element.choice) { index, item in
                OnboardingCard(
                    title: item.title,
                    description: item.description,
                    isSelected: selected == item.choice,
                    anySelected: selected != nil,
                    action: { onSelect(item.choice) }
                )
                .scaleEffect(cardsAppeared ? 1.0 : 0.85)
                .opacity(cardsAppeared ? 1.0 : 0)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)
                        .delay(Double(index) * 0.15),
                    value: cardsAppeared
                )
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

// MARK: - Staggered Word Reveal

private struct StaggeredWordReveal: View {
    let text: String
    @State private var appeared = false

    var body: some View {
        let words = text.split(separator: " ").map(String.init)
        FlowLayout(spacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(
                        .easeOut(duration: 0.8).delay(Double(index) * 0.08),
                        value: appeared
                    )
            }
        }
        .chloeEditorialHeading()
        .multilineTextAlignment(.center)
        .onAppear { appeared = true }
    }
}

#Preview {
    ArchetypeQuizView(viewModel: OnboardingViewModel())
}
