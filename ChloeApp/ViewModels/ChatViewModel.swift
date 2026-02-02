import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var errorMessage: String?
    @Published var conversationTitle: String = "New Conversation"

    private let geminiService = GeminiService.shared
    private let safetyService = SafetyService.shared
    private let storageService = StorageService.shared
    private let analystService = AnalystService.shared

    private var isAnalyzing = false
    private var backgroundObserver: Any?

    var conversationId: String?

    init() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: .appDidEnterBackground,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.triggerAnalysisIfPending() }
        }
    }

    deinit {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        errorMessage = nil

        // Safety check
        let safetyResult = safetyService.checkSafety(message: text)
        if safetyResult.blocked, let crisisType = safetyResult.crisisType {
            let userMsg = Message(conversationId: conversationId, role: .user, text: text)
            messages.append(userMsg)

            let crisisResponse = safetyService.getCrisisResponse(for: crisisType)
            let chloeMsg = Message(conversationId: conversationId, role: .chloe, text: crisisResponse)
            messages.append(chloeMsg)
            saveMessages()
            return
        }

        // Rate limiting
        var usage = storageService.loadDailyUsage()
        let profile = storageService.loadProfile()
        if profile?.subscriptionTier != .premium && usage.messageCount >= FREE_DAILY_MESSAGE_LIMIT {
            errorMessage = "You've reached your daily free message limit. Upgrade to Premium for unlimited messages."
            return
        }

        // Add user message
        let userMsg = Message(conversationId: conversationId, role: .user, text: text)
        messages.append(userMsg)

        // Increment daily usage
        usage.messageCount += 1
        try? storageService.saveDailyUsage(usage)

        // Record streak activity
        StreakService.shared.recordActivity(source: .chat)

        // Cancel engagement notifications on re-engagement
        NotificationService.shared.cancelEngagementNotifications()

        isTyping = true

        do {
            // Build personalized prompt
            let archetype: UserArchetype? = {
                guard let answers = profile?.preferences?.archetypeAnswers else { return nil }
                return ArchetypeService.shared.classify(answers: answers)
            }()

            let systemPrompt = buildPersonalizedPrompt(
                displayName: profile?.displayName ?? "babe",
                preferences: profile?.preferences,
                archetype: archetype
            )

            let userFacts = storageService.loadUserFacts()
                .filter { $0.isActive }
                .map { $0.fact }

            let response = try await geminiService.sendMessage(
                messages: messages,
                systemPrompt: systemPrompt,
                userFacts: userFacts
            )

            let chloeMsg = Message(conversationId: conversationId, role: .chloe, text: response)
            messages.append(chloeMsg)
            saveMessages()

            // Background analysis trigger (every 3 messages)
            let msgsSinceAnalysis = storageService.loadMessagesSinceAnalysis() + 1
            storageService.saveMessagesSinceAnalysis(msgsSinceAnalysis)
            if msgsSinceAnalysis >= 3 {
                storageService.saveMessagesSinceAnalysis(0)
                Task.detached { [weak self] in
                    await self?.triggerBackgroundAnalysis()
                }
            }
        } catch {
            errorMessage = "Message failed to send. Tap to retry."
            lastFailedText = text
        }

        isTyping = false
    }

    var lastFailedText: String?

    func retryLastMessage() async {
        guard let text = lastFailedText else { return }
        lastFailedText = nil
        // Remove the user message that had no response
        if let last = messages.last, last.role == .user {
            messages.removeLast()
        }
        inputText = text
        await sendMessage()
    }

    func startNewChat() {
        conversationId = UUID().uuidString
        messages = []
        inputText = ""
        errorMessage = nil
        isTyping = false
        conversationTitle = "New Conversation"
    }

    func loadConversation(id: String) {
        conversationId = id
        messages = storageService.loadMessages(forConversation: id)
        conversationTitle = storageService.loadConversation(id: id)?.title ?? "New Conversation"
    }

    private func saveMessages() {
        guard let id = conversationId else { return }
        try? storageService.saveMessages(messages, forConversation: id)

        // Create or update conversation metadata
        var convo = storageService.loadConversation(id: id)
            ?? Conversation(id: id, title: "New Conversation")
        convo.updatedAt = Date()
        try? storageService.saveConversation(convo)

        // Generate title from first user message (one-time)
        if convo.title == "New Conversation",
           let firstUserMsg = messages.first(where: { $0.role == .user }) {
            Task {
                if let title = try? await geminiService.generateTitle(for: firstUserMsg.text) {
                    var updated = convo
                    updated.title = title
                    try? storageService.saveConversation(updated)
                    conversationTitle = title
                }
            }
        }
    }

    private func triggerBackgroundAnalysis() async {
        guard !isAnalyzing else { return }
        guard !messages.isEmpty else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let profile = storageService.loadProfile()
            let existingFacts = storageService.loadUserFacts()
            let factStrings = existingFacts.filter { $0.isActive }.map { $0.fact }
            let lastSummary = storageService.loadLatestSummary()
            let currentVibe = storageService.loadLatestVibe()
            let displayName = profile?.displayName

            let result = try await analystService.analyze(
                messages: messages,
                userFacts: factStrings,
                lastSummary: lastSummary,
                currentVibe: currentVibe,
                displayName: displayName
            )

            await MainActor.run {
                // Update vibe
                storageService.saveLatestVibe(result.vibeScore)

                // Save session summary for fallback notifications
                storageService.saveLatestSummary(result.summary)

                // Merge facts
                let lastMessageId = messages.last?.id
                let updatedFacts = analystService.mergeNewFacts(
                    existing: existingFacts,
                    from: result,
                    userId: profile?.id,
                    sourceMessageId: lastMessageId
                )
                try? storageService.saveUserFacts(updatedFacts)

                // Schedule engagement notification if analyst flagged one
                if let opportunity = result.engagementOpportunity,
                   opportunity.triggerNotification,
                   let text = opportunity.notificationText {
                    let name = profile?.displayName ?? "babe"
                    let processedText = text.replacingOccurrences(of: "[Name]", with: name)
                    NotificationService.shared.scheduleEngagementNotification(text: processedText)
                }

                // Push pattern to insight queue for Chloe to surface later
                if let pattern = result.engagementOpportunity?.patternDetected {
                    storageService.pushInsight(pattern)
                }
            }
        } catch {
            // Background analysis failures are silent
        }
    }

    // MARK: - Background Analysis on App Exit

    func triggerAnalysisIfPending() async {
        guard !isAnalyzing else { return }
        let pending = storageService.loadMessagesSinceAnalysis()
        guard pending > 0, !messages.isEmpty else { return }
        storageService.saveMessagesSinceAnalysis(0)
        await triggerBackgroundAnalysis()
    }
}
