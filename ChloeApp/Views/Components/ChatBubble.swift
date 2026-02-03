import SwiftUI

struct ChatBubble: View {
    let message: Message
    let conversationId: String
    let previousUserMessage: String?
    var feedbackState: MessageFeedbackState = .none
    var onFeedback: ((FeedbackRating) -> Void)?
    var onReport: (() -> Void)?

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Spacing.xxxs) {
                // Image (if present)
                if let imageUri = message.imageUri,
                   let uiImage = UIImage(contentsOfFile: imageUri) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Text (if non-empty)
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 17, weight: isUser ? .medium : .light))
                        .foregroundColor(.chloeTextPrimary)
                        .lineSpacing(8.5)
                }

                // Feedback buttons (only for Chloe messages)
                if !isUser {
                    feedbackButtons
                }
            }
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

    @ViewBuilder
    private var feedbackButtons: some View {
        HStack(spacing: 12) {
            // Thumbs up
            Button {
                onFeedback?(.helpful)
            } label: {
                Image(systemName: feedbackState == .helpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .foregroundColor(feedbackState == .helpful ? .chloePrimary : .chloeTextTertiary)
            }
            .accessibilityIdentifier(feedbackState == .helpful ? "thumbsUpFilled" : "thumbsUp")
            .disabled(feedbackState != .none)

            // Thumbs down
            Button {
                onFeedback?(.notHelpful)
            } label: {
                Image(systemName: feedbackState == .notHelpful ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .foregroundColor(feedbackState == .notHelpful ? .red : .chloeTextTertiary)
            }
            .accessibilityIdentifier(feedbackState == .notHelpful ? "thumbsDownFilled" : "thumbsDown")
            .disabled(feedbackState != .none)

            // Report
            Button {
                onReport?()
            } label: {
                Image(systemName: feedbackState == .reported ? "flag.fill" : "flag")
                    .foregroundColor(feedbackState == .reported ? .orange : .chloeTextTertiary)
            }
            .accessibilityIdentifier(feedbackState == .reported ? "reportSubmitted" : "report")
            .disabled(feedbackState == .reported)
        }
        .font(.system(size: 14))
        .padding(.top, 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubble(
            message: Message(role: .user, text: "Hey Chloe!"),
            conversationId: "preview-conv",
            previousUserMessage: nil
        )
        ChatBubble(
            message: Message(role: .chloe, text: "Hey gorgeous! How are you feeling today?"),
            conversationId: "preview-conv",
            previousUserMessage: "Hey Chloe!",
            feedbackState: .none,
            onFeedback: { rating in print("Feedback: \(rating)") },
            onReport: { print("Report tapped") }
        )
    }
    .padding()
}
