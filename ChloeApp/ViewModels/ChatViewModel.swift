import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var pendingImage: UIImage? = nil
    @Published var isTyping = false
    @Published var errorMessage: String?
    @Published var conversationTitle: String = "New Conversation"
    @Published var isLimitReached = false

    private let geminiService = GeminiService.shared
    private let safetyService = SafetyService.shared
    private let storageService = SyncDataService.shared
    private let analystService = AnalystService.shared

    private var isAnalyzing = false
    private var backgroundObserver: Any?

    private let goodbyeTemplates: [String] = [
        "Hey — I loved talking to you today. I'm going to recharge, but I'll be right here tomorrow. You've got this tonight. \u{1F49C}",
        "That's a wrap for today, babe. Let everything we talked about settle. I'll be back tomorrow with fresh energy for you.",
        "I'm signing off for now, but I'm not going anywhere. Sleep on it, and come find me tomorrow. I'll be waiting.",
    ]

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
        let image = pendingImage
        guard !text.isEmpty || image != nil else { return }

        inputText = ""
        pendingImage = nil
        errorMessage = nil

        // Save image to disk if present
        var imageUri: String? = nil
        if let image {
            imageUri = storageService.saveChatImage(image)
        }

        // Safety check
        let safetyResult = safetyService.checkSafety(message: text)
        if safetyResult.blocked, let crisisType = safetyResult.crisisType {
            let userMsg = Message(conversationId: conversationId, role: .user, text: text, imageUri: imageUri)
            messages.append(userMsg)

            let crisisResponse = safetyService.getCrisisResponse(for: crisisType)
            let chloeMsg = Message(conversationId: conversationId, role: .chloe, text: crisisResponse)
            messages.append(chloeMsg)
            saveMessages()
            return
        }

        // Rate limiting — block at 6th message (after goodbye on 5th)
        var usage = storageService.loadDailyUsage()
        let profile = storageService.loadProfile()
        if profile?.subscriptionTier != .premium && usage.messageCount >= FREE_DAILY_MESSAGE_LIMIT {
            isLimitReached = true
            return
        }
        let isLastFreeMessage = profile?.subscriptionTier != .premium
            && usage.messageCount == FREE_DAILY_MESSAGE_LIMIT - 1

        // Add user message
        let userMsg = Message(conversationId: conversationId, role: .user, text: text, imageUri: imageUri)
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

            let currentVibe = storageService.loadLatestVibe()

            var systemPrompt = buildPersonalizedPrompt(
                displayName: profile?.displayName ?? "babe",
                preferences: profile?.preferences,
                archetype: archetype,
                vibeScore: currentVibe
            )

            // Soft spiral override — per-message, not per-session
            if safetyService.checkSoftSpiral(message: text) {
                // Replace whatever mode was set with GENTLE SUPPORT
                if let range = systemPrompt.range(of: #"CURRENT MODE: [^\n]+"#, options: .regularExpression) {
                    systemPrompt.replaceSubrange(range, with: "CURRENT MODE: GENTLE SUPPORT")
                }
            }

            let userFacts = storageService.loadUserFacts()
                .filter { $0.isActive }
                .map { $0.fact }

            // Load session context for GeminiService (decoupled from StorageService)
            let isNewConversation = messages.count <= 1
            let lastSummary = isNewConversation ? storageService.loadLatestSummary() : nil
            let insight = !isNewConversation ? storageService.popInsight() : nil

            let response = try await geminiService.sendMessage(
                messages: messages,
                systemPrompt: systemPrompt,
                userFacts: userFacts,
                lastSummary: lastSummary,
                insight: insight
            )

            let chloeMsg = Message(conversationId: conversationId, role: .chloe, text: response)
            messages.append(chloeMsg)
            saveMessages()

            // Append warm goodbye after last free message
            if isLastFreeMessage {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                let goodbye = goodbyeTemplates.randomElement() ?? goodbyeTemplates[0]
                let goodbyeMsg = Message(conversationId: conversationId, role: .chloe, text: goodbye)
                messages.append(goodbyeMsg)
                saveMessages()
                isLimitReached = true
            }

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
        isLimitReached = false
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
