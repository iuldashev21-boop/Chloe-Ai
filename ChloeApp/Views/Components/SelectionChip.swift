import SwiftUI

struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.chloeSubheadline)
                .foregroundColor(isSelected ? .white : .chloePrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.chloePrimary : Color.chloePrimaryLight)
                .cornerRadius(Spacing.cornerRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                        .stroke(Color.chloePrimary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        SelectionChip(title: "Confidence", isSelected: true, action: {})
        SelectionChip(title: "Self-Love", isSelected: false, action: {})
    }
}
