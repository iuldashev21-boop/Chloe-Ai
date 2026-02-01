import SwiftUI
import CoreMotion

struct ParallaxCardModifier: ViewModifier {
    @StateObject private var motion = MotionManager()
    var intensity: Double = 8

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(motion.pitch * intensity),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(motion.roll * intensity),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: motion.pitch)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: motion.roll)
    }
}

private final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    init() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            self?.pitch = data.attitude.pitch
            self?.roll = data.attitude.roll
        }
    }

    deinit {
        manager.stopDeviceMotionUpdates()
    }
}

extension View {
    func parallaxTilt(intensity: Double = 8) -> some View {
        modifier(ParallaxCardModifier(intensity: intensity))
    }
}

#Preview {
    RoundedRectangle(cornerRadius: 20)
        .fill(
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 300, height: 200)
        .overlay(
            Text("Parallax Card")
                .font(.title2.bold())
                .foregroundStyle(.white)
        )
        .parallaxTilt()
        .padding()
}
