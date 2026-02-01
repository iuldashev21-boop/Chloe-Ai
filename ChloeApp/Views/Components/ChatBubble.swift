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
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isUser ? Color.chloeUserBubble : Color.chloePrimaryLight)
                .cornerRadius(Spacing.cornerRadius)

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
