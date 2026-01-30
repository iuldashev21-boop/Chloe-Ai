import SwiftUI

struct AffirmationsView: View {
    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Text("Affirmations")
                    .font(.chloeTitle)
                    .foregroundColor(.chloeTextPrimary)

                Text("Coming soon")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)
            }
        }
        .navigationTitle("Affirmations")
    }
}

#Preview {
    NavigationStack {
        AffirmationsView()
    }
}
