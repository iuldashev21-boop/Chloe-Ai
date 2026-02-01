import SwiftUI

struct EtherealDustParticles: View {
    private struct Particle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var phaseX: CGFloat
        var phaseY: CGFloat
        var swayAmplitudeX: CGFloat
        var swayAmplitudeY: CGFloat
        var opacity: Double
    }

    @State private var particles: [Particle] = []

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = CGFloat(timeline.date.timeIntervalSinceReferenceDate)

                for particle in particles {
                    let elapsed = time * particle.speed
                    let xPos = particle.x * size.width + sin(elapsed + particle.phaseX) * particle.swayAmplitudeX
                    let yPos = particle.y * size.height + cos(elapsed + particle.phaseY) * particle.swayAmplitudeY

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
            .blur(radius: 4)
        }
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<12).map { _ in
                Particle(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    size: CGFloat.random(in: 8...20),
                    speed: CGFloat.random(in: 0.05...0.15),
                    phaseX: CGFloat.random(in: 0...(2 * .pi)),
                    phaseY: CGFloat.random(in: 0...(2 * .pi)),
                    swayAmplitudeX: CGFloat.random(in: 20...60),
                    swayAmplitudeY: CGFloat.random(in: 15...40),
                    opacity: 0.03
                )
            }
        }
    }
}
