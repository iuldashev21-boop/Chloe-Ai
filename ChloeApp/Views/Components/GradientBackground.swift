import SwiftUI

struct GradientBackground: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            LinearGradient(
                colors: [.chloeGradientStart, .chloeGradientEnd],
                startPoint: isLandscape ? .leading : .top,
                endPoint: isLandscape ? .trailing : .bottom
            )
            .ignoresSafeArea()
        }
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
