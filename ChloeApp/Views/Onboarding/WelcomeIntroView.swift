import SwiftUI

struct WelcomeIntroView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onContinue: () -> Void = {}

    @State private var revealedWordCount = 0
    @State private var buttonAppeared = false
    @State private var dissolving = false
    @State private var animationTask: Task<Void, Never>?

    // Particle burst
    @State private var particles: [DissolveParticle] = []
    @State private var particlesLaunched = false

    private let introText = "I\u{2019}m Chloe. Let\u{2019}s unlock your most magnetic self."

    private var words: [String] {
        introText.components(separatedBy: " ")
    }

    var body: some View {
        ZStack {
            VStack(spacing: Spacing.lg) {
                Spacer()

                // Space for the container-level orb
                Spacer().frame(height: 100)

                // Kinetic typography — words fade in one-by-one
                kineticText
                    .padding(.horizontal, Spacing.screenHorizontal + Spacing.sm)
                    .opacity(dissolving ? 0 : 1)
                    .scaleEffect(dissolving ? 0.8 : 1)
                    .offset(y: dissolving ? -80 : 0)

                Spacer()

                Button {
                    triggerDissolve()
                } label: {
                    ChloeButtonLabel(title: "Begin My Journey")
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Begin my journey")
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xl)
                .opacity(dissolving ? 0 : (buttonAppeared ? 1 : 0))
                .scaleEffect(dissolving ? 0.8 : 1)
                .offset(y: dissolving ? -40 : (buttonAppeared ? 0 : 20))
            }

            // Dissolve particles
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.white)
                    .frame(width: particle.size, height: particle.size)
                    .opacity(particlesLaunched ? 0 : 0.8)
                    .position(
                        x: particlesLaunched ? particle.endX : particle.startX,
                        y: particlesLaunched ? particle.endY : particle.startY
                    )
                    .blur(radius: 1)
            }
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

    // MARK: - Dissolve Transition

    private func triggerDissolve() {
        guard !dissolving else { return }

        // Generate particles from center of text area
        let centerX: CGFloat = UIScreen.main.bounds.width / 2
        let centerY: CGFloat = UIScreen.main.bounds.height * 0.5
        let orbY: CGFloat = UIScreen.main.bounds.height * 0.08

        particles = (0..<15).map { _ in
            DissolveParticle(
                startX: centerX + CGFloat.random(in: -100...100),
                startY: centerY + CGFloat.random(in: -40...40),
                endX: centerX + CGFloat.random(in: -20...20),
                endY: orbY + CGFloat.random(in: -10...10),
                size: CGFloat.random(in: 2...4)
            )
        }

        // Dissolve text + button
        withAnimation(.easeIn(duration: 0.5)) {
            dissolving = true
        }

        // Launch particles toward orb
        withAnimation(.easeIn(duration: 0.6).delay(0.1)) {
            particlesLaunched = true
        }

        // Trigger transition after dissolve
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onContinue()
        }
    }

    // MARK: - Animation Sequence

    private func startRevealSequence() {
        animationTask = Task {
            // Wait for container orb to appear
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }

            // Words reveal one-by-one (0.3s per word)
            for i in 1...words.count {
                revealedWordCount = i
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
            }

            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            // Button slides up
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                buttonAppeared = true
            }
        }
    }
}

// MARK: - Dissolve Particle

private struct DissolveParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
}

#Preview {
    WelcomeIntroView(viewModel: OnboardingViewModel())
}
