import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                        }

                        if viewModel.isTyping {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.sm)
                }

                ChatInputBar(text: $viewModel.inputText) {
                    Task { await viewModel.sendMessage() }
                }
            }
        }
        .navigationTitle("Chat with Chloe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
