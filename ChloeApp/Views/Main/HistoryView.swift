import SwiftUI

struct HistoryView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var displayLimit = 50
    @Environment(\.dismiss) private var dismiss
    var onSelectConversation: ((Conversation) -> Void)?

    /// All conversations sorted by most recent, loaded once
    @State private var allConversations: [Conversation] = []

    var body: some View {
        ZStack {
            GradientBackground()

            if isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.chloePrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if conversations.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "No conversations yet",
                    subtitle: "Start chatting with Chloe to see your history here"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(conversations) { convo in
                            Button {
                                onSelectConversation?(convo)
                                dismiss()
                            } label: {
                                conversationCard(convo)
                            }
                            .buttonStyle(.plain)
                        }

                        // "Load more" button when there are more conversations
                        if displayLimit < allConversations.count {
                            Button {
                                displayLimit += 50
                                conversations = Array(allConversations.prefix(displayLimit))
                            } label: {
                                Text("Load more conversations")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.chloePrimary)
                                    .padding(.vertical, Spacing.sm)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.sm)
                }
                .refreshable {
                    allConversations = SyncDataService.shared.loadConversations()
                        .sorted(by: { $0.updatedAt > $1.updatedAt })
                    conversations = Array(allConversations.prefix(displayLimit))
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarRole(.editor)
        .onAppear {
            allConversations = SyncDataService.shared.loadConversations()
                .sorted(by: { $0.updatedAt > $1.updatedAt })
            conversations = Array(allConversations.prefix(displayLimit))
            isLoading = false
        }
    }

    private func conversationCard(_ convo: Conversation) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(convo.title)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)
                .lineLimit(2)

            HStack {
                Text(convo.updatedAt, style: .relative)
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextTertiary)
                Text("ago")
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .chloeCardStyle(cornerRadius: Spacing.cornerRadiusLarge)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
