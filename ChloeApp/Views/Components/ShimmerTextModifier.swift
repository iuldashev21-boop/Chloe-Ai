import SwiftUI

struct LuminousBloomModifier: ViewModifier {
    var trigger: Bool

    @State private var shimmerPosition: CGFloat = -0.3
    @State private var shimmerDone = false
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1.1
    @State private var blurRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .blur(radius: blurRadius)
            .overlay {
                if !shimmerDone && opacity > 0 {
                    GeometryReader { geo in
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.3), location: shimmerPosition - 0.1),
                                .init(color: .white, location: shimmerPosition),
                                .init(color: .white.opacity(0.3), location: shimmerPosition + 0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                    }
                }
            }
            .onChange(of: trigger) {
                guard trigger else { return }
                // Reset state
                shimmerPosition = -0.3
                shimmerDone = false
                opacity = 0
                scale = 1.1
                blurRadius = 20

                // Shimmer sweep
                withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                    shimmerPosition = 1.3
                }

                // Bloom entrance: opacity, scale, blur
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    opacity = 1
                    scale = 1.0
                    blurRadius = 0
                }

                // Remove shimmer mask after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    shimmerDone = true
                }
            }
    }
}

extension View {
    func luminousBloom(trigger: Bool) -> some View {
        modifier(LuminousBloomModifier(trigger: trigger))
    }
}
