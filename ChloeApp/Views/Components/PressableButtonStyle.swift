import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(
                color: Color(hex: "#B76E79").opacity(configuration.isPressed ? 0.5 : 0.3),
                radius: configuration.isPressed ? 30 : 25,
                y: configuration.isPressed ? 8 : 12
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
