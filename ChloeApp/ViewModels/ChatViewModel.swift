import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var errorMessage: String?

    private let geminiService = GeminiService.shared
    private let safetyService = SafetyService.shared
    private let storageService = StorageService.shared
    private let analystService = AnalystService.shared

    var conversationId: String?

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
            errorMessage = error.localizedDescription
        }

        isTyping = false
    }

    func startNewChat() {
        conversationId = UUID().uuidString
        messages = []
        inputText = ""
        errorMessage = nil
        isTyping = false
    }

    func loadConversation(id: String) {
        conversationId = id
        messages = storageService.loadMessages(forConversation: id)
    }

    private func saveMessages() {
        guard let id = conversationId else { return }
        try? storageService.saveMessages(messages, forConversation: id)
    }

    private func triggerBackgroundAnalysis() async {
        guard !messages.isEmpty else { return }
        do {
            let result = try await analystService.analyze(messages: messages)

            await MainActor.run {
                // Update vibe
                storageService.saveLatestVibe(result.vibeScore)

                // Merge facts
                let existingFacts = storageService.loadUserFacts()
                let lastMessageId = messages.last?.id
                let updatedFacts = analystService.mergeNewFacts(
                    existing: existingFacts,
                    from: result,
                    userId: storageService.loadProfile()?.id,
                    sourceMessageId: lastMessageId
                )
                try? storageService.saveUserFacts(updatedFacts)
            }
        } catch {
            // Background analysis failures are silent
        }
    }
}
