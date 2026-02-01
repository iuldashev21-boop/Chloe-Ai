import SwiftUI

struct InputStardustParticles: View {
    var isEmitting: Bool

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
                guard isEmitting else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let elapsed = CGFloat(time) * particle.speed
                    // Rise upward within ~40pt height
                    let yPos = size.height - (elapsed * 6).truncatingRemainder(dividingBy: 40)
                    let xSway = sin(elapsed + particle.phase) * particle.swayAmplitude
                    let xPos = particle.x * size.width + xSway

                    let rect = CGRect(
                        x: xPos - particle.size / 2,
                        y: yPos - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )

                    let color = Color(red: 0.75, green: 0.55, blue: 0.50)
                    context.opacity = particle.opacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(color)
                    )
                }
            }
            .blur(radius: 0.5)
        }
        .frame(height: 40)
        .allowsHitTesting(false)
        .opacity(isEmitting ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isEmitting)
        .onAppear {
            particles = (0..<6).map { _ in
                Particle(
                    x: CGFloat.random(in: 0.1...0.9),
                    y: CGFloat.random(in: 0...40),
                    size: CGFloat.random(in: 2...4),
                    speed: CGFloat.random(in: 0.4...1.0),
                    phase: CGFloat.random(in: 0...(2 * .pi)),
                    swayAmplitude: CGFloat.random(in: 3...8),
                    opacity: Double.random(in: 0.2...0.45)
                )
            }
        }
    }
}
