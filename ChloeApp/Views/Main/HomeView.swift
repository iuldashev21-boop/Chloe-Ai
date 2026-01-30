import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                ChloeAvatar(size: 60)

                Text("Welcome back")
                    .font(.chloeTitle)
                    .foregroundColor(.chloeTextPrimary)

                Text("Coming soon")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)
            }
        }
        .navigationTitle("Home")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
