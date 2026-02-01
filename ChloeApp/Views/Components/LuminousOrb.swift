import SwiftUI

struct LuminousOrb: View {
    var size: CGFloat = Spacing.orbSize
    var isFieldFocused: Bool = false

    @State private var sparkleGlow = false
    @State private var sparkleRotation: Double = 0

    private var breathDuration: Double { isFieldFocused ? 1.5 : 4.0 }

    var body: some View {
        ZStack {
            // MARK: - Fluid Nebula (Canvas swirl)
            FluidNebula()
                .frame(width: 80, height: 80)
                .clipShape(Circle())

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
            .shadow(color: Color(hex: "#B76E79").opacity(0.7), radius: 10)
            .shadow(color: Color(hex: "#B76E79").opacity(0.3), radius: 25)
            .rotationEffect(.degrees(sparkleRotation))
            .scaleEffect(sparkleGlow ? 1.1 : 0.9)
            .opacity(sparkleGlow ? 1.0 : 0.7)
        }
        .frame(width: 80, height: 80)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                sparkleGlow = true
            }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
        .onChange(of: isFieldFocused) { _, focused in
            // Re-trigger breathing at faster/slower rate
            sparkleGlow = false
            withAnimation(.easeInOut(duration: focused ? 1.5 : 4.0).repeatForever(autoreverses: true)) {
                sparkleGlow = true
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Fluid Nebula (Canvas-based swirling gradient)

private struct FluidNebula: View {
    private let colors: [Color] = [
        Color(hex: "#FFF8F0"),
        Color(hex: "#FFE5D9"),
        Color(hex: "#B76E79")
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
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
