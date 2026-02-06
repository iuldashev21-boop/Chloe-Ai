import SwiftUI

struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.chloeAccentMuted)
                    .frame(width: 8, height: 8)
                    .scaleEffect(reduceMotion ? 1.0 : (animating ? 1.0 : 0.5))
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.chloePrimaryLight)
        .cornerRadius(Spacing.cornerRadius)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chloe is typing")
        .onAppear { animating = true }
    }
}

#Preview {
    TypingIndicator()
}
