import SwiftUI

struct HistoryView: View {
    @State private var conversations: [Conversation] = []
    @Environment(\.dismiss) private var dismiss
    var onSelectConversation: ((Conversation) -> Void)?

    var body: some View {
        ZStack {
            GradientBackground()

            if conversations.isEmpty {
                ChloeEmptyState(iconName: "clock.arrow.circlepath", message: "No conversations yet")
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
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarRole(.editor)
        .onAppear {
            conversations = SyncDataService.shared.loadConversations()
                .sorted(by: { $0.updatedAt > $1.updatedAt })
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
