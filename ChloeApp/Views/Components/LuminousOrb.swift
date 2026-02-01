import SwiftUI

struct LuminousOrb: View {
    var size: CGFloat = Spacing.orbSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let baseRadius = min(canvasSize.width, canvasSize.height) / 2 * 0.75

                // Breathing scale: pulses at ~1Hz (60bpm)
                let breathe = sin(time * 2 * .pi) * 0.04 + 1.0
                let radius = baseRadius * breathe

                // Build fluid blob path with sine-wave distortion
                let segments = 64
                var path = Path()
                for i in 0...segments {
                    let angle = (Double(i) / Double(segments)) * 2 * .pi
                    // Superimposed sine waves for organic blob shape
                    let distortion = 1.0
                        + sin(angle * 3 + time * 1.8) * 0.06
                        + sin(angle * 5 - time * 2.4) * 0.03
                        + sin(angle * 7 + time * 1.2) * 0.02
                    let r = radius * distortion
                    let x = center.x + CGFloat(cos(angle) * r)
                    let y = center.y + CGFloat(sin(angle) * r)
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.closeSubpath()

                // Radial gradient fill: ethereal gold center → accent edge
                let gradient = Gradient(stops: [
                    .init(color: Color.chloeEtherealGold, location: 0.0),
                    .init(color: Color.chloeEtherealGold.opacity(0.9), location: 0.25),
                    .init(color: Color.chloeEtherealGold.opacity(0.6), location: 0.45),
                    .init(color: Color.chloeAccent.opacity(0.8), location: 0.7),
                    .init(color: Color.chloeAccent.opacity(0.4), location: 1.0)
                ])
                let shading = GraphicsContext.Shading.radialGradient(
                    gradient,
                    center: center,
                    startRadius: 0,
                    endRadius: CGFloat(radius * 1.1)
                )
                context.fill(path, with: shading)
            }
            .frame(width: size, height: size)
            .overlay {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.chloeEtherealGold.opacity(0.3),
                                Color.chloeEtherealGold.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: size * 0.25,
                            endRadius: size * 0.6
                        )
                    )
                    .frame(width: size * 1.4, height: size * 1.4)
                    .blur(radius: size * 0.15)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size * 1.4, height: size * 1.4)
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            LuminousOrb(size: 80)
            LuminousOrb(size: 120)
        }
    }
}
