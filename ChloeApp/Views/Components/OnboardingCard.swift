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
                    .foregroundColor(isSelected ? .white : .chloeTextPrimary)

                Text(description)
                    .font(.chloeCaptionLight)
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .chloeTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "#B76E79").opacity(0.5))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color(hex: "#B76E79") : Color.white.opacity(0.2),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: isSelected ? Color(hex: "#B76E79").opacity(0.3) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .opacity(isSelected ? 1.0 : 0.85)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
