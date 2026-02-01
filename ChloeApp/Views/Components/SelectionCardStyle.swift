import SwiftUI

struct SelectionCardModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                    .fill(isSelected ? Color.chloePrimaryLight : Color.chloeSurface)
            )
            .shadow(
                color: isSelected
                    ? Color.chloePrimary.opacity(0.15)
                    : Color.black.opacity(0.04),
                radius: isSelected ? 10 : 4,
                x: 0,
                y: isSelected ? 3 : 2
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .opacity(isSelected ? 1.0 : 0.75)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

extension View {
    func selectionCard(isSelected: Bool) -> some View {
        modifier(SelectionCardModifier(isSelected: isSelected))
    }
}
