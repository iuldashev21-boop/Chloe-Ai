import SwiftUI

struct LuminousOrb: View {
    var size: CGFloat = Spacing.orbSize
    var isFieldFocused: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var sparkleGlow = false
    @State private var sparkleRotation: Double = 0
    @State private var isAnimating = false

    private var breathDuration: Double { isFieldFocused ? 1.5 : 4.0 }

    var body: some View {
        ZStack {
            // MARK: - Fluid Nebula (Canvas swirl)
            if !reduceMotion {
                FluidNebula(isAnimating: isAnimating)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                // Static gradient circle for reduced motion
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.chloeGradientStart, Color(hex: "#FFE5D9"), Color.chloePrimary],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
            }

            // MARK: - Sparkle (The Heart)
            ZStack {
                // Outer bloom — soft white halo
                Image(systemName: "sparkle")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(.white.opacity(0.5))
                    .blur(radius: 4)

                // Core sparkle — crisp and bright
                Image(systemName: "sparkle")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.white)
            }
            .shadow(color: .white.opacity(0.9), radius: 4)
            .shadow(color: Color.chloePrimary.opacity(0.5), radius: 18)
            .rotationEffect(.degrees(reduceMotion ? 0 : sparkleRotation))
            .scaleEffect(reduceMotion ? 1.0 : (sparkleGlow ? 1.1 : 0.9))
            .opacity(reduceMotion ? 1.0 : (sparkleGlow ? 1.0 : 0.7))
        }
        .frame(width: 80, height: 80)
        .drawingGroup()
        .onAppear {
            isAnimating = true
            startSparkleAnimations()
        }
        .onDisappear {
            isAnimating = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                isAnimating = true
                startSparkleAnimations()
            } else {
                isAnimating = false
            }
        }
        .onChange(of: isFieldFocused) { _, focused in
            guard !reduceMotion else { return }
            // Re-trigger breathing at faster/slower rate
            sparkleGlow = false
            withAnimation(.easeInOut(duration: focused ? 1.5 : 4.0).repeatForever(autoreverses: true)) {
                sparkleGlow = true
            }
        }
        .allowsHitTesting(false)
    }

    private func startSparkleAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            sparkleGlow = true
        }
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            sparkleRotation = 360
        }
    }
}

// MARK: - Fluid Nebula (Canvas-based swirling gradient)

private struct FluidNebula: View {
    var isAnimating: Bool

    private let colors: [Color] = [
        Color.chloeGradientStart,
        Color(hex: "#FFE5D9"),
        Color.chloePrimary
    ]

    var body: some View {
        TimelineView(isAnimating ? .animation : .animation(minimumInterval: 31_536_000)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let cx = size.width / 2
                let cy = size.height / 2
                let radius = size.width / 2

                // Draw 3 overlapping soft blobs that orbit the center
                for (i, color) in colors.enumerated() {
                    let phase = Double(i) * (2.0 * .pi / 3.0)
                    let orbitRadius = radius * 0.3
                    let speed = 0.15 + Double(i) * 0.05

                    let bx = cx + CGFloat(cos(t * speed + phase)) * orbitRadius
                    let by = cy + CGFloat(sin(t * speed + phase)) * orbitRadius
                    let blobSize = radius * CGFloat(0.9 + 0.15 * sin(t * 0.3 + phase))

                    let rect = CGRect(
                        x: bx - blobSize,
                        y: by - blobSize,
                        width: blobSize * 2,
                        height: blobSize * 2
                    )

                    context.opacity = 0.6
                    context.blendMode = .normal
                    context.fill(
                        Circle().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [color, color.opacity(0)]),
                            center: CGPoint(x: bx, y: by),
                            startRadius: 0,
                            endRadius: blobSize
                        )
                    )
                }
            }
        }
        .blur(radius: 8)
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            LuminousOrb(size: 80, isFieldFocused: false)
            LuminousOrb(size: 80, isFieldFocused: true)
        }
    }
}
