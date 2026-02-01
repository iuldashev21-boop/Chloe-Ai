import SwiftUI

struct BloomTextModifier: ViewModifier {
    var trigger: Bool

    @State private var revealFraction: CGFloat = 0
    @State private var blurRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .blur(radius: blurRadius)
            .mask(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: max(0, revealFraction - 0.15)),
                            .init(color: .clear, location: revealFraction)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.3)
                }
            )
            .onChange(of: trigger) {
                guard trigger else { return }
                revealFraction = 0
                blurRadius = 20

                withAnimation(.easeOut(duration: 1.0)) {
                    revealFraction = 1.0
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    blurRadius = 0
                }
            }
    }
}

extension View {
    func bloomReveal(trigger: Bool) -> some View {
        modifier(BloomTextModifier(trigger: trigger))
    }
}

#Preview {
    @Previewable @State var trigger = false

    VStack(spacing: 32) {
        Text("Bloom Text Reveal")
            .font(.title)
            .bloomReveal(trigger: trigger)

        Button("Trigger") {
            trigger = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                trigger = true
            }
        }
    }
    .padding()
}
