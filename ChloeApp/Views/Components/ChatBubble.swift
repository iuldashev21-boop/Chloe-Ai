import SwiftUI

struct ChatBubble: View {
    let message: Message
    let conversationId: String
    let previousUserMessage: String?
    var feedbackState: MessageFeedbackState = .none
    var onFeedback: ((FeedbackRating) -> Void)?
    var onReport: (() -> Void)?
    var onOptionSelect: ((StrategyOption) -> Void)?

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Spacing.xxxs) {
                // Image (if present) — loaded as thumbnail at display resolution
                if let imageUri = message.imageUri {
                    ChatImageThumbnailView(imagePath: imageUri, maxWidth: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel(isUser ? "You sent an image" : "Chloe sent an image")
                }

                // Text (if non-empty)
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(isUser ? .chloeBodyDefault.weight(.medium) : .chloeBodyDefault.weight(.light))
                        .foregroundColor(.chloeTextPrimary)
                        .lineSpacing(8.5)
                }

                // Strategy options (v2 agentic)
                if let options = message.options, !options.isEmpty, !isUser {
                    StrategyOptionsView(options: options) { selected in
                        onOptionSelect?(selected)
                    }
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityMessageLabel)

            if !isUser { Spacer(minLength: 60) }
        }
    }

    /// Constructs a VoiceOver label with sender context
    private var accessibilityMessageLabel: String {
        let prefix = isUser ? "You said" : "Chloe said"
        if message.text.isEmpty {
            return isUser ? "You sent an image" : "Chloe sent an image"
        }
        return "\(prefix): \(message.text)"
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
            .accessibilityLabel(feedbackState == .helpful ? "Marked as helpful" : "Mark as helpful")
            .accessibilityIdentifier(feedbackState == .helpful ? "thumbsUpFilled" : "thumbsUp")
            .disabled(feedbackState != .none)

            // Thumbs down
            Button {
                onFeedback?(.notHelpful)
            } label: {
                Image(systemName: feedbackState == .notHelpful ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .foregroundColor(feedbackState == .notHelpful ? .red : .chloeTextTertiary)
            }
            .accessibilityLabel(feedbackState == .notHelpful ? "Marked as not helpful" : "Mark as not helpful")
            .accessibilityIdentifier(feedbackState == .notHelpful ? "thumbsDownFilled" : "thumbsDown")
            .disabled(feedbackState != .none)

            // Report
            Button {
                onReport?()
            } label: {
                Image(systemName: feedbackState == .reported ? "flag.fill" : "flag")
                    .foregroundColor(feedbackState == .reported ? .orange : .chloeTextTertiary)
            }
            .accessibilityLabel(feedbackState == .reported ? "Response reported" : "Report this response")
            .accessibilityIdentifier(feedbackState == .reported ? "reportSubmitted" : "report")
            .disabled(feedbackState == .reported)
        }
        .font(.system(size: 14))
        .padding(.top, 4)
    }
}

// MARK: - Chat Image Thumbnail (loads at display resolution via ImageIO)

private struct ChatImageThumbnailView: View {
    let imagePath: String
    let maxWidth: CGFloat

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: maxWidth)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.chloePrimaryLight)
                    .frame(width: maxWidth, height: 160)
            }
        }
        .task(id: imagePath) {
            thumbnail = UIImage.thumbnail(atPath: imagePath, maxPixelSize: maxWidth)
        }
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
