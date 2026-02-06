import SwiftUI

struct EtherealDustParticles: View {
    private struct Particle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var phaseX: CGFloat
        var swayAmplitude: CGFloat
        var opacity: Double
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var particles: [Particle] = []
    @State private var isAnimating = false

    var body: some View {
        if reduceMotion {
            // Show a static subtle overlay instead of animated particles
            Color.clear
        } else {
        TimelineView(isAnimating ? .animation : .animation(minimumInterval: 31_536_000)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)

                for particle in particles {
                    // Drift upward continuously, wrap around when off top
                    let yTravel = t * particle.speed * 15
                    var yPos = particle.y * size.height - yTravel.truncatingRemainder(dividingBy: size.height + 40)
                    if yPos < -20 { yPos += size.height + 40 }

                    // Gentle horizontal sway
                    let xPos = particle.x * size.width + sin(t * 0.3 + particle.phaseX) * particle.swayAmplitude

                    let rect = CGRect(
                        x: xPos - particle.size / 2,
                        y: yPos - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    context.opacity = particle.opacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(.white)
                    )
                }
            }
            .blur(radius: 1)
        }
        .allowsHitTesting(false)
        .onAppear {
            isAnimating = true

            // Original ambient dust (large, very faint)
            let dust: [Particle] = (0..<8).map { _ in
                Particle(
                    x: .random(in: 0...1),
                    y: .random(in: 0...1),
                    size: .random(in: 8...16),
                    speed: .random(in: 0.02...0.06),
                    phaseX: .random(in: 0...(2 * .pi)),
                    swayAmplitude: .random(in: 20...50),
                    opacity: 0.03
                )
            }

            // Ethereal bokeh (tiny, brighter, drift upward)
            let bokeh: [Particle] = (0..<10).map { _ in
                Particle(
                    x: .random(in: 0.05...0.95),
                    y: .random(in: 0...1),
                    size: .random(in: 1...3),
                    speed: .random(in: 0.08...0.2),
                    phaseX: .random(in: 0...(2 * .pi)),
                    swayAmplitude: .random(in: 8...20),
                    opacity: 0.1
                )
            }

            particles = dust + bokeh
        }
        .onDisappear {
            isAnimating = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            isAnimating = (newPhase == .active)
        }
        } // end else (reduceMotion)
    }
}
