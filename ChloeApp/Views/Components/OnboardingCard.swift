import SwiftUI

struct OnboardingCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.chloeSubheadline)
                    .foregroundColor(isSelected ? .chloePrimary : .chloeTextPrimary)

                Text(description)
                    .font(.chloeCaptionLight)
                    .foregroundColor(isSelected ? .chloePrimary.opacity(0.8) : .chloeTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(isSelected ? Color.chloePrimaryLight : Color.clear)
            .background(.ultraThinMaterial)
            .cornerRadius(Spacing.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                    .stroke(isSelected ? Color.chloePrimary.opacity(0.4) : Color.chloeBorderWarm, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    HStack {
        OnboardingCard(title: "Marriage", description: "Building a forever partnership", isSelected: false, action: {})
        OnboardingCard(title: "Glow Up", description: "Becoming your most radiant self", isSelected: true, action: {})
    }
    .padding()
    .background(Color.chloeBackground)
}
