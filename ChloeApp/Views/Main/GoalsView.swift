import SwiftUI

struct GoalsView: View {
    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Text("Goals")
                    .font(.chloeTitle)
                    .foregroundColor(.chloeTextPrimary)

                Text("Coming soon")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)
            }
        }
        .navigationTitle("Goals")
    }
}

#Preview {
    NavigationStack {
        GoalsView()
    }
}
