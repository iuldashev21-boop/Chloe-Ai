import SwiftUI

struct OnboardingCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    var anySelected: Bool = false
    var action: () -> Void

    private static let cardShape = RoundedRectangle(cornerRadius: 20)
    private static let accentColor = Color(hex: "#B76E79")

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
                    Self.cardShape.fill(.ultraThinMaterial)
                    if isSelected {
                        Self.cardShape.fill(Self.accentColor.opacity(0.5))
                    }
                }
            )
            .clipShape(Self.cardShape)
            .overlay(
                Self.cardShape.stroke(
                    isSelected ? Self.accentColor : Color.white.opacity(0.2),
                    lineWidth: isSelected ? 2 : 0.5
                )
            )
            .shadow(color: isSelected ? Self.accentColor.opacity(0.3) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .opacity(isSelected ? 1.0 : (anySelected ? 0.4 : 0.85))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .animation(.easeOut(duration: 0.2), value: anySelected)
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
