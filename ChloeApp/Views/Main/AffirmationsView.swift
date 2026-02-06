import SwiftUI

struct AffirmationsView: View {
    var body: some View {
        ZStack {
            GradientBackground()

            EmptyStateView(
                icon: "sparkles",
                title: "Affirmations coming soon",
                subtitle: "Daily affirmations to nurture your mindset and support your growth"
            )
        }
        .navigationTitle("Affirmations")
    }
}

#Preview {
    NavigationStack {
        AffirmationsView()
    }
}
