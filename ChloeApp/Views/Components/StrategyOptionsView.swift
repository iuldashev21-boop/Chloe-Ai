import SwiftUI

struct StrategyOptionsView: View {
    let options: [StrategyOption]
    var onSelect: (StrategyOption) -> Void

    @State private var selectedOption: StrategyOption?

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(options) { option in
                OptionCard(
                    option: option,
                    isSelected: selectedOption?.label == option.label,
                    anySelected: selectedOption != nil,
                    action: {
                        selectedOption = option
                        onSelect(option)
                    }
                )
            }
        }
        .padding(.top, Spacing.xs)
    }
}

struct OptionCard: View {
    let option: StrategyOption
    let isSelected: Bool
    var anySelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(option.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .chloeTextPrimary : .chloeTextSecondary)

                Text(option.action)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.chloeTextSecondary)
                    .lineLimit(2)

                if !option.outcome.isEmpty {
                    Text("\(option.outcome)")
                        .font(.system(size: 13, weight: .light, design: .default))
                        .foregroundColor(.chloeTextTertiary)
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.chloePrimary : Color.chloePrimary.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .opacity(anySelected && !isSelected ? 0.5 : 1.0)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StrategyOptionsView(
        options: [
            StrategyOption(
                label: "Option A: The Boss Move",
                action: "Go silent. Let him wonder where you went.",
                outcome: "He will wonder where you went"
            ),
            StrategyOption(
                label: "Option B: The Quick Fix",
                action: "Double text and ask what's up",
                outcome: "You lose leverage"
            )
        ],
        onSelect: { print("Selected: \($0.label)") }
    )
    .padding()
    .background(Color.chloeBackground)
}
