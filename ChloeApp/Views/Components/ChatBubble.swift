import SwiftUI

struct ChatBubble: View {
    let message: Message

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(message.text)
                .font(.system(size: 17, weight: isUser ? .medium : .light))
                .foregroundColor(.chloeTextPrimary)
                .lineSpacing(8.5)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isUser ? Color.chloeUserBubble : Color.chloePrimaryLight)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isUser ? Color.clear : Color.chloePrimary, lineWidth: 0.5)
                )

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubble(message: Message(role: .user, text: "Hey Chloe!"))
        ChatBubble(message: Message(role: .chloe, text: "Hey gorgeous! How are you feeling today?"))
    }
    .padding()
}
