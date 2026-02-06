import SwiftUI

struct ArchetypeQuizView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var answers: [Int: ArchetypeChoice] = [:]

    @State private var wordRevealID = UUID()
    @State private var cardsAppeared = false

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    private let pages: [(question: String, options: [(choice: ArchetypeChoice, title: String, description: String)])] = [
        (
            question: "When you imagine your most powerful self, she is...",
            options: [
                (.a, "Magnetic", "The room goes quiet — effortless."),
                (.b, "Commanding", "One look, and they fall in line."),
                (.c, "Inspiring", "You speak and something shifts inside them."),
                (.d, "Electric", "You walk in — everything changes."),
            ]
        ),
        (
            question: "Your secret weapon is...",
            options: [
                (.a, "Warmth", "They let their guard down around you."),
                (.b, "Intuition", "You know before they say a word."),
                (.c, "Drive", "Nothing stands between you and the vision."),
                (.d, "Mystery", "They can't stop wondering about you."),
            ]
        ),
        (
            question: "When life gets heavy, you reset by...",
            options: [
                (.a, "Reflecting", "Stillness, silence, pages of truth."),
                (.b, "Moving", "Sweat, motion, letting the body lead."),
                (.c, "Creating", "Pouring the chaos into something beautiful."),
                (.d, "Escaping", "New air, new streets, disappearing for a while."),
            ]
        ),
        (
            question: "In your dream relationship, he's drawn to your...",
            options: [
                (.a, "Sensuality", "A slow glance that says everything."),
                (.b, "Standards", "The quiet power of 'I don't settle.'"),
                (.c, "Depth", "You see through him — and he craves it."),
                (.d, "Wildness", "Unpredictable, untamed, utterly alive."),
            ]
        ),
    ]

    private var currentPage: (question: String, options: [(choice: ArchetypeChoice, title: String, description: String)]) {
        let safeIndex = min(max(viewModel.quizPage, 0), pages.count - 1)
        return pages[safeIndex]
    }

    private var currentAnswer: ArchetypeChoice? {
        answers[viewModel.quizPage]
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Space for container-level guide orb
            Spacer().frame(height: 80)

            questionView(
                question: currentPage.question,
                options: currentPage.options,
                selected: currentAnswer,
                onSelect: { choice in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    answers[viewModel.quizPage] = choice
                }
            )

            Spacer()

            Button {
                if viewModel.quizPage < 3 {
                    withAnimation(.easeInOut) {
                        viewModel.quizPage += 1
                    }
                } else {
                    guard answers.count >= 4,
                          let energy = answers[0],
                          let strength = answers[1],
                          let recharge = answers[2],
                          let allure = answers[3] else { return }
                    viewModel.preferences.archetypeAnswers = ArchetypeAnswers(
                        energy: energy,
                        strength: strength,
                        recharge: recharge,
                        allure: allure
                    )
                    viewModel.nextStep()
                }
            } label: {
                ChloeButtonLabel(
                    title: "Continue",
                    isEnabled: currentAnswer != nil
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
