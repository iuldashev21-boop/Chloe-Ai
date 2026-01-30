import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.chloeGradientStart, .chloeGradientEnd],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

extension View {
    func chloeBackground() -> some View {
        self.background(GradientBackground())
    }
}

#Preview {
    GradientBackground()
}
