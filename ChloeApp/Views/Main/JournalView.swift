import SwiftUI

struct JournalView: View {
    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Text("Journal")
                    .font(.chloeTitle)
                    .foregroundColor(.chloeTextPrimary)

                Text("Coming soon")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)
            }
        }
        .navigationTitle("Journal")
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
}
