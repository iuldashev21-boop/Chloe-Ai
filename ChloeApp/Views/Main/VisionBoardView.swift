import SwiftUI

struct VisionBoardView: View {
    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Text("Vision Board")
                    .font(.chloeTitle)
                    .foregroundColor(.chloeTextPrimary)

                Text("Coming soon")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)
            }
        }
        .navigationTitle("Vision Board")
    }
}

#Preview {
    NavigationStack {
        VisionBoardView()
    }
}
