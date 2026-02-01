import SwiftUI

struct StardustParticles: View {
    private struct Particle {
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var phase: CGFloat
        var swayAmplitude: CGFloat
        var opacity: Double
    }

    @State private var particles: [Particle] = []

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let elapsed = CGFloat(time) * particle.speed
                    let yPos = (particle.y - elapsed * 8).truncatingRemainder(dividingBy: size.height)
                    let wrappedY = yPos < 0 ? yPos + size.height : yPos
                    let xSway = sin(elapsed + particle.phase) * particle.swayAmplitude
                    let xPos = particle.x * size.width + xSway

                    let rect = CGRect(
                        x: xPos - particle.size / 2,
                        y: wrappedY - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    let color: Color = particle.size > 5
                        ? .white
                        : Color(red: 0.75, green: 0.55, blue: 0.50)  // dusty rose

                    context.opacity = particle.opacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(color)
                    )
                }
            }
            .blur(radius: 1)
        }
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<18).map { _ in
                Particle(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...800),
                    size: CGFloat.random(in: 3...8),
                    speed: CGFloat.random(in: 0.3...0.8),
                    phase: CGFloat.random(in: 0...(2 * .pi)),
                    swayAmplitude: CGFloat.random(in: 5...15),
                    opacity: Double.random(in: 0.25...0.50)
                )
            }
        }
    }
}
