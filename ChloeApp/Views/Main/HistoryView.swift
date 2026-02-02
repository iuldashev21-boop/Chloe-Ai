import SwiftUI

struct HistoryView: View {
    @State private var conversations: [Conversation] = []
    @Environment(\.dismiss) private var dismiss
    var onSelectConversation: ((Conversation) -> Void)?

    var body: some View {
        ZStack {
            GradientBackground()

            if conversations.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(.chloeTextTertiary)
                        .accessibilityHidden(true)
                    Text("No conversations yet")
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextTertiary)
                }
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
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.chloeRosewood.opacity(0.12),
            radius: 16,
            x: 0,
            y: 6
        )
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
