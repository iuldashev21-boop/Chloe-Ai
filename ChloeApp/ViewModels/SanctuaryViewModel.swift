import Foundation
import SwiftUI

@MainActor
class SanctuaryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var displayName: String = "babe"
    @Published var profileImage: UIImage?
    @Published var ghostMessages: [Message] = []
    @Published var conversations: [Conversation] = []
    @Published var latestVibe: VibeScore?
    @Published var streak: GlowUpStreak?
    @Published var feedbackStates: [String: MessageFeedbackState] = [:]

    /// Cached sorted list of recent conversations for the sidebar.
    /// Updated only when `conversations` changes via `loadConversations()`.
    @Published private(set) var recentConversations: [Conversation] = []

    // MARK: - Status Text

    var statusText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Ready when you are."
        case 12..<17: return "I'm holding space for you."
        default: return "I'm here. No rush."
        }
    }

    // MARK: - Initial Data Loading

    func loadData() {
        loadUserData()
        loadGhostMessages(conversationId: nil)
        loadConversations()
    }

    // MARK: - User Data

    func loadUserData() {
        if let profile = SyncDataService.shared.loadProfile() {
            displayName = profile.displayName.isEmpty ? "babe" : profile.displayName
        }
        if let data = SyncDataService.shared.loadProfileImage() {
            profileImage = UIImage(data: data)
        } else {
            profileImage = nil
        }
    }

    // MARK: - Ghost Messages

    func loadGhostMessages(conversationId: String?) {
        let targetId: String? = conversationId ?? SyncDataService.shared.loadConversations()
            .sorted(by: { $0.updatedAt > $1.updatedAt })
            .first?.id
        guard let id = targetId else {
            ghostMessages = []
            return
        }
        let messages = SyncDataService.shared.loadMessages(forConversation: id)
        ghostMessages = Array(messages.suffix(2))
    }

    // MARK: - Conversations & Sidebar Data

    func loadConversations() {
        conversations = SyncDataService.shared.loadConversations()
            .sorted(by: { $0.updatedAt > $1.updatedAt })
        // Update cached recentConversations: starred first, then by most recent, top 10
        recentConversations = conversations.sorted { a, b in
            if a.starred != b.starred { return a.starred }
            return a.updatedAt > b.updatedAt
        }.prefix(10).map { $0 }
        latestVibe = SyncDataService.shared.loadLatestVibe()
        let loadedStreak = SyncDataService.shared.loadStreak()
        streak = loadedStreak.currentStreak > 0 ? loadedStreak : nil
    }

    // MARK: - Conversation Management

    func renameConversation(id: String, newTitle: String, chatVM: ChatViewModel) {
        try? SyncDataService.shared.renameConversation(id: id, newTitle: newTitle)
        loadConversations()
        if chatVM.conversationId == id {
            chatVM.conversationTitle = newTitle
        }
    }

    func deleteConversation(id: String, chatVM: ChatViewModel) -> Bool {
        guard SyncDataService.shared.deleteConversation(id: id) else {
            return false
        }
        loadConversations()
        return true
    }

    func toggleStarConversation(id: String) {
        try? SyncDataService.shared.toggleConversationStar(id: id)
        loadConversations()
    }

    // MARK: - Feedback

    /// Pre-compute previous user message for each message index.
    /// Returns a dictionary mapping message ID to the previous user message text.
    func buildPreviousUserMessageMap(for messages: [Message]) -> [String: String] {
        var map: [String: String] = [:]
        var lastUserText: String? = nil
        for message in messages {
            if message.role != .user, let text = lastUserText {
                map[message.id] = text
            }
            if message.role == .user {
                lastUserText = message.text
            }
        }
        return map
    }

    func handleFeedback(for message: Message, conversationId: String?, previousUserMessage: String?, rating: FeedbackRating) {
        feedbackStates[message.id] = rating == .helpful ? .helpful : .notHelpful

        Task {
            let feedback = Feedback(
                messageId: message.id,
                conversationId: conversationId ?? "",
                userMessage: previousUserMessage ?? "",
                aiResponse: message.text,
                rating: rating
            )
            try? await FeedbackService.shared.submitFeedback(feedback)
        }
    }

    // MARK: - Profile Image Reload

    func reloadProfileImage() {
        if let data = SyncDataService.shared.loadProfileImage() {
            profileImage = UIImage(data: data)
        } else {
            profileImage = nil
        }
    }
}
