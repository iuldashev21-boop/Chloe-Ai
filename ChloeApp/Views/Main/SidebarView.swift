import SwiftUI

enum SidebarDestination {
    case journal, history, visionBoard, goals, affirmations, settings
}

struct SidebarView: View {
    @Binding var isOpen: Bool
    var conversations: [Conversation]
    var latestVibe: VibeScore?
    var streak: GlowUpStreak?
    var currentConversationId: String?
    var displayName: String = "babe"
    var profileImageData: Data? = nil
    var onNewChat: () -> Void
    var onSelectConversation: (Conversation) -> Void
    var onNavigate: (SidebarDestination) -> Void
    var onRenameConversation: (String, String) -> Void
    var onDeleteConversation: (String) -> Void
    var onToggleStarConversation: (String) -> Void

    @State private var conversationToRename: Conversation?
    @State private var renameText: String = ""
    @State private var conversationToDelete: Conversation?

    private var sidebarWidth: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? UIScreen.main.bounds.width) * 0.8
    }

    /// Starred first, then sorted by most recent
    private var sortedConversations: [Conversation] {
        conversations.sorted { a, b in
            if a.starred != b.starred { return a.starred }
            return a.updatedAt > b.updatedAt
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Spacer().frame(height: 60)
            Text("Chloe")
                .font(.chloeSidebarAppName)
                .foregroundStyle(Color.chloeTextPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)

            // Navigate section
            sectionHeader("NAVIGATE")

            navItem(icon: "plus", label: "New Chat", identifier: "new-chat-button") { onNewChat() }
            navItem(icon: "text.book.closed", label: "Journal", identifier: "journal-button") { onNavigate(.journal) }
            navItem(icon: "clock", label: "History", identifier: "history-button") { onNavigate(.history) }
            navItem(icon: "rectangle.on.rectangle.angled", label: "Vision Board", identifier: "vision-board-button") { onNavigate(.visionBoard) }
            navItem(icon: "target", label: "Goals", identifier: "goals-button") { onNavigate(.goals) }
            // Hidden for v1 - UI not ready (backend notifications still work)
            // navItem(icon: "sparkles", label: "Affirmations", identifier: "affirmations-button") { onNavigate(.affirmations) }

            // Glow Up Streak
            if let streak, streak.currentStreak > 0 {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.chloePrimary)
                    Text("\(streak.currentStreak) day streak")
                        .font(.chloeSidebarChatItem)
                        .foregroundColor(.chloeTextSecondary)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xs)
            }

            Spacer().frame(height: Spacing.lg)

            // Recent section
            sectionHeader("RECENT")

            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xxxs) {
                    ForEach(sortedConversations.prefix(10)) { convo in
                        conversationRow(convo)
                    }
                }
            }

            Spacer()

            // Profile pill
            profilePill
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
        }
        .frame(width: sidebarWidth)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Color.chloePrimary.opacity(0.06)
            }
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.chloeRosewood.opacity(0.3))
                .frame(width: 1)
                .shadow(color: Color.chloeRosewood.opacity(0.15), radius: 8, x: 2)
        }
        .ignoresSafeArea()
        .alert("Rename Conversation", isPresented: Binding(
            get: { conversationToRename != nil },
            set: { if !$0 { conversationToRename = nil } }
        )) {
            TextField("New name", text: $renameText)
            Button("Cancel", role: .cancel) { conversationToRename = nil }
            Button("Rename") {
                if let convo = conversationToRename {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onRenameConversation(convo.id, trimmed)
                    }
                }
                conversationToRename = nil
            }
        }
        .confirmationDialog(
            "Delete Conversation",
            isPresented: Binding(
                get: { conversationToDelete != nil },
                set: { if !$0 { conversationToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let convo = conversationToDelete {
                    onDeleteConversation(convo.id)
                }
                conversationToDelete = nil
            }
            Button("Cancel", role: .cancel) { conversationToDelete = nil }
        } message: {
            Text("This conversation and all its messages will be permanently deleted.")
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.chloeSidebarSectionHeader)
            .tracking(2)
            .foregroundColor(.chloeTextTertiary)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xs)
    }

    // MARK: - Nav Item

    private func navItem(icon: String, label: String, identifier: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.chloePrimary)
                    .frame(width: 24)
                Text(label)
                    .font(.chloeSidebarMenuItem)
                    .foregroundColor(.chloeTextPrimary)
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier ?? label.lowercased().replacingOccurrences(of: " ", with: "-"))
    }

    // MARK: - Profile Pill

    private var profilePill: some View {
        Button { onNavigate(.settings) } label: {
            HStack(spacing: Spacing.xs) {
                // Profile image or initial circle
                if let profileImageData, let uiImage = UIImage(data: profileImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.chloePrimary.opacity(0.25), lineWidth: 1)
                        )
                } else {
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.chloeTextPrimary)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(Color.chloePrimary.opacity(0.25), lineWidth: 1)
                                )
                        )
                }

                Text(displayName)
                    .font(.chloeSidebarChatItem)
                    .foregroundColor(.chloeTextPrimary)
                    .lineLimit(1)
            }
            .padding(.trailing, Spacing.sm)
            .padding(.leading, Spacing.xxxs)
            .padding(.vertical, Spacing.xxxs)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.chloePrimary.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayName) profile")
        .accessibilityIdentifier("settings-button")
    }

    // MARK: - Conversation Row

    private func conversationRow(_ convo: Conversation) -> some View {
        let isActive = convo.id == currentConversationId

        return Button {
            onSelectConversation(convo)
        } label: {
            HStack(spacing: Spacing.xs) {
                if convo.starred {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.chloePrimary.opacity(0.6))
                        .frame(width: 16)
                }
                Text(convo.title)
                    .font(.chloeSidebarChatItem)
                    .fontWeight(convo.starred ? .medium : .regular)
                    .foregroundColor(isActive ? .chloeTextPrimary : .chloeTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                // Three-dot context menu
                Menu {
                    Button {
                        renameText = convo.title
                        conversationToRename = convo
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        onToggleStarConversation(convo.id)
                    } label: {
                        Label(
                            convo.starred ? "Unstar" : "Star",
                            systemImage: convo.starred ? "star.slash" : "star"
                        )
                    }
                    Button(role: .destructive) {
                        conversationToDelete = convo
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.chloeTextTertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.chloePrimary.opacity(0.10) : Color.clear)
                    .padding(.horizontal, Spacing.xs)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(convo.title)
        .accessibilityIdentifier("conversation-\(convo.id)")
    }
}

#Preview {
    SidebarView(
        isOpen: .constant(true),
        conversations: [
            Conversation(title: "Morning check-in", starred: true),
            Conversation(title: "Late night thoughts"),
            Conversation(title: "Goal setting session"),
        ],
        latestVibe: .medium,
        streak: GlowUpStreak(currentStreak: 5, longestStreak: 12, lastActiveDate: "2026-02-02"),
        currentConversationId: nil,
        displayName: "Temo",
        onNewChat: {},
        onSelectConversation: { _ in },
        onNavigate: { _ in },
        onRenameConversation: { _, _ in },
        onDeleteConversation: { _ in },
        onToggleStarConversation: { _ in }
    )
}
