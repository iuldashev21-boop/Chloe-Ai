import SwiftUI

struct WelcomeIntroView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onContinue: () -> Void = {}

    @State private var orbAppeared = false
    @State private var revealedWordCount = 0
    @State private var buttonAppeared = false
    @State private var animationTask: Task<Void, Never>?

    private let introText = "I\u{2019}m Chloe. Let\u{2019}s unlock your most magnetic self."

    private var words: [String] {
        introText.components(separatedBy: " ")
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Luminous orb entrance
            ChloeAvatar(size: 80)
                .opacity(orbAppeared ? 1 : 0)
                .scaleEffect(orbAppeared ? 1 : 0.5)

            // Kinetic typography — words fade in one-by-one
            kineticText
                .padding(.horizontal, Spacing.screenHorizontal + Spacing.sm)

            Spacer()

            Button {
                onContinue()
            } label: {
                ChloeButtonLabel(title: "Begin My Journey")
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Begin my journey")
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
            .opacity(buttonAppeared ? 1 : 0)
            .offset(y: buttonAppeared ? 0 : 20)
        }
        .onAppear {
            startRevealSequence()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }

    // MARK: - Kinetic Text (per-word fade + rise)

    private var kineticText: some View {
        FlowLayout(spacing: 6, lineSpacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                let isVisible = index < revealedWordCount
                Text(word)
                    .font(.chloeOnboardingQuestion)
                    .tracking(26 * 0.03)
                    .foregroundColor(.chloeTextPrimary)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 5)
                    .animation(.easeOut(duration: 0.3), value: revealedWordCount)
            }
        }
    }

    // MARK: - Animation Sequence

    private func startRevealSequence() {
        animationTask = Task {
            // Phase 1: Orb springs in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                orbAppeared = true
            }

            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }

            // Phase 2: Words reveal one-by-one (0.3s per word)
            for i in 1...words.count {
                revealedWordCount = i
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
            }

            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            // Phase 3: Button slides up
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                buttonAppeared = true
            }
        }
    }
}

#Preview {
    WelcomeIntroView(viewModel: OnboardingViewModel())
}
