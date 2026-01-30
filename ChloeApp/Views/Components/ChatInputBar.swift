import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TextField("Message Chloe...", text: $text, axis: .vertical)
                .font(.chloeBodyDefault)
                .lineLimit(1...5)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.chloeSurface)
                .cornerRadius(Spacing.cornerRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                        .stroke(Color.chloeBorder, lineWidth: 1)
                )

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.isBlank ? .chloeTextTertiary : .chloePrimary)
            }
            .disabled(text.isBlank)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.xs)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ChatInputBar(text: .constant(""), onSend: {})
}
