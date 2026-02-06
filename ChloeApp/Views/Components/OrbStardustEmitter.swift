import SwiftUI

struct OrbStardustEmitter: View {
    var isEmitting: Bool
    var orbSize: CGFloat = Spacing.orbSizeSanctuary
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Particle {
        var angle: CGFloat      // radial direction from center
        var speed: CGFloat      // outward drift speed
        var size: CGFloat       // circle diameter
        var phase: CGFloat      // animation offset
        var opacity: Double
    }

    @State private var particles: [Particle] = []

    var body: some View {
        if reduceMotion {
            // Skip particle animation entirely when Reduce Motion is on
            EmptyView()
        } else {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                guard isEmitting else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let orbRadius = orbSize * 0.75 / 2 // match LuminousOrb baseRadius

                for particle in particles {
                    let elapsed = CGFloat(time) * particle.speed + particle.phase
                    // Particle lifecycle: 0 → 1.5s then wraps
                    let lifecycle = elapsed.truncatingRemainder(dividingBy: 1.5)
                    let progress = lifecycle / 1.5 // 0…1

                    // Start at orb edge, drift outward
                    let distance = orbRadius + progress * orbSize * 0.5
                    // Slight upward bias
                    let angle = particle.angle
                    let x = center.x + cos(angle) * distance
                    let y = center.y + sin(angle) * distance - progress * 8

                    // Fade out over lifetime
                    let fadeOpacity = particle.opacity * Double(1.0 - progress)

                    let rect = CGRect(
                        x: x - particle.size / 2,
                        y: y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.opacity = fadeOpacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(.chloeEtherealGold)
                    )
                }
            }
            .blur(radius: 0.8)
        }
        .frame(width: orbSize * 1.6, height: orbSize * 1.6)
        .allowsHitTesting(false)
        .opacity(isEmitting ? 1 : 0)
        .animation(.easeInOut(duration: 0.4), value: isEmitting)
        .onAppear {
            particles = (0..<10).map { _ in
                Particle(
                    angle: CGFloat.random(in: 0...(2 * .pi)),
                    speed: CGFloat.random(in: 0.6...1.2),
                    size: CGFloat.random(in: 2...4),
                    phase: CGFloat.random(in: 0...1.5),
                    opacity: Double.random(in: 0.3...0.6)
                )
            }
        }
        } // end else (reduceMotion)
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()
        OrbStardustEmitter(isEmitting: true, orbSize: 140)
    }
}
