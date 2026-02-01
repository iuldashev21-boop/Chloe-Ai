import SwiftUI

enum SidebarDestination {
    case journal, history, visionBoard, settings
}

struct SidebarView: View {
    @Binding var isOpen: Bool
    var conversations: [Conversation]
    var latestVibe: VibeScore?
    var onNewChat: () -> Void
    var onSelectConversation: (Conversation) -> Void
    var onNavigate: (SidebarDestination) -> Void

    private var sidebarWidth: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? UIScreen.main.bounds.width) * 0.8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Spacer().frame(height: 60)
            Text("C H L O E")
                .font(.custom("TenorSans-Regular", size: 12))
                .tracking(3)
                .foregroundColor(.chloeTextSecondary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)

            // Navigate section
            sectionHeader("NAVIGATE")

            navItem(icon: "sparkles", label: "New Chat") { onNewChat() }
            navItem(icon: "book", label: "Journal") { onNavigate(.journal) }
            navItem(icon: "clock.arrow.circlepath", label: "History") { onNavigate(.history) }
            navItem(icon: "star", label: "Vision Board") { onNavigate(.visionBoard) }

            Spacer().frame(height: Spacing.lg)

            // Recent section
            sectionHeader("RECENT")

            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xxxs) {
                    ForEach(conversations.prefix(10)) { convo in
                        conversationRow(convo)
                    }
                }
            }

            Spacer()

            // Settings
            Divider()
                .background(Color.chloeBorder.opacity(0.3))
                .padding(.horizontal, Spacing.sm)

            navItem(icon: "gearshape", label: "Settings") { onNavigate(.settings) }
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
            // Right edge glow
            Rectangle()
                .fill(Color.chloeRosewood.opacity(0.3))
                .frame(width: 1)
                .shadow(color: Color.chloeRosewood.opacity(0.15), radius: 8, x: 2)
        }
        .ignoresSafeArea()
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

    private func navItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
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
    }

    // MARK: - Conversation Row

    private func conversationRow(_ convo: Conversation) -> some View {
        Button {
            onSelectConversation(convo)
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: sentimentIcon(for: convo))
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.chloeTextTertiary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                Text(convo.title)
                    .font(.chloeSidebarChatItem)
                    .foregroundColor(.chloeTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xxs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(convo.title)
    }

    private func sentimentIcon(for convo: Conversation) -> String {
        // Use global vibe for most recent, neutral for others
        let isLatest = convo.id == conversations.first?.id
        guard isLatest, let vibe = latestVibe else { return "circle.fill" }
        switch vibe {
        case .low: return "moon.fill"
        case .medium: return "sun.max.fill"
        case .high: return "star.fill"
        }
    }
}

#Preview {
    SidebarView(
        isOpen: .constant(true),
        conversations: [
            Conversation(title: "Morning check-in"),
            Conversation(title: "Late night thoughts"),
            Conversation(title: "Goal setting session"),
        ],
        latestVibe: .medium,
        onNewChat: {},
        onSelectConversation: { _ in },
        onNavigate: { _ in }
    )
}
