import Foundation
import SwiftUI
import Combine

/// Loading states for agentic pipeline
enum LoadingState: Equatable {
    case idle
    case routing      // Phase 1: Triage/Classification
    case generating   // Phase 2: Strategist response
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var pendingImage: UIImage? = nil
    @Published var isTyping = false
    @Published var loadingState: LoadingState = .idle  // v2 multi-phase loading
    @Published var errorMessage: String?
    @Published var conversationTitle: String = "New Conversation"
    @Published var isLimitReached = false
    @Published var isOffline = false

    private let geminiService: GeminiServiceProtocol
    private let safetyService: SafetyServiceProtocol
    private let storageService: SyncDataServiceProtocol
    private let archetypeService: ArchetypeServiceProtocol
    private let analystService = AnalystService.shared
    private let networkMonitor: NetworkMonitor

    private var isAnalyzing = false
    private var cancellables = Set<AnyCancellable>()
    private var errorDismissTask: Task<Void, Never>?

    private let goodbyeTemplates: [String] = [
        "Hey — I loved talking to you today. I'm going to recharge, but I'll be right here tomorrow. You've got this tonight. \u{1F49C}",
        "That's a wrap for today, babe. Let everything we talked about settle. I'll be back tomorrow with fresh energy for you.",
        "I'm signing off for now, but I'm not going anywhere. Sleep on it, and come find me tomorrow. I'll be waiting.",
    ]

    var conversationId: String?

    init(
        geminiService: GeminiServiceProtocol = GeminiService.shared,
        safetyService: SafetyServiceProtocol = SafetyService.shared,
        storageService: SyncDataServiceProtocol = SyncDataService.shared,
        archetypeService: ArchetypeServiceProtocol = ArchetypeService.shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.geminiService = geminiService
        self.safetyService = safetyService
        self.storageService = storageService
        self.archetypeService = archetypeService
        self.networkMonitor = networkMonitor

        // Observe network connectivity changes
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isOffline = !connected
                if !connected {
                    self?.showError("No internet connection.", autoDismiss: false)
                } else if self?.errorMessage == "No internet connection." {
                    self?.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }

    private var isSending = false

    func sendMessage() async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }

        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = pendingImage
        guard !text.isEmpty || image != nil else { return }

        // Offline guard — fail fast with clear feedback
        if isOffline {
            showError("No internet connection. Please check your network and try again.", autoDismiss: false)
            return
        }

        // Input length guard — Gemini has per-request token limits; reject obviously oversized input
        if text.count > 10_000 {
            showError("Message is too long. Please shorten it and try again.")
            return
        }

        inputText = ""
        pendingImage = nil
        errorMessage = nil
        errorDismissTask?.cancel()

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
        // V1_PREMIUM_FOR_ALL bypasses rate limits for all users
        var usage = storageService.loadDailyUsage()
        let profile = storageService.loadProfile()
        if !V1_PREMIUM_FOR_ALL && profile?.subscriptionTier != .premium && usage.messageCount >= FREE_DAILY_MESSAGE_LIMIT {
            isLimitReached = true
            return
        }
        let isLastFreeMessage = !V1_PREMIUM_FOR_ALL
            && profile?.subscriptionTier != .premium
            && usage.messageCount == FREE_DAILY_MESSAGE_LIMIT - 1

        // Add user message
        let userMsg = Message(conversationId: conversationId, role: .user, text: text, imageUri: imageUri)
        messages.append(userMsg)
        trackSignal("chat.messageSent")

        // Increment daily usage
        usage.messageCount += 1
        try? storageService.saveDailyUsage(usage)

        // Record streak activity
        StreakService.shared.recordActivity(source: .chat)

        // Cancel engagement notifications on re-engagement
        NotificationService.shared.cancelEngagementNotifications()

        isTyping = true

        do {
            let archetype: UserArchetype? = {
                guard let answers = profile?.preferences?.archetypeAnswers else { return nil }
                return archetypeService.classify(answers: answers)
            }()

            let currentVibe = storageService.loadLatestVibe()
            let userFacts = storageService.loadUserFacts()
                .filter { $0.isActive }
                .map { $0.fact }
            let isNewConversation = messages.count <= 1
            let lastSummary = isNewConversation ? storageService.loadLatestSummary() : nil
            let insight = !isNewConversation ? storageService.popInsight() : nil

            // Phase 1: Triage (Router Classification)
            loadingState = .routing

            let classification = try await geminiService.classifyMessage(
                message: text,
                systemPrompt: Prompts.router,
                attempt: 1
            )

            #if DEBUG
            print("[ChatViewModel] Router: \(classification.category.rawValue) / \(classification.urgency.rawValue)")
            #endif

            // Safety override: If router detects SAFETY_RISK, use crisis response
            if classification.category == .safetyRisk {
                loadingState = .idle
                isTyping = false
                let crisisResponse = safetyService.getCrisisResponse(for: .selfHarm)
                let chloeMsg = Message(conversationId: conversationId, role: .chloe, text: crisisResponse)
                messages.append(chloeMsg)
                saveMessages()
                return
            }

            // Phase 2: Strategy (Strategist Response)
            loadingState = .generating

            // Soft spiral override — per-message, not per-session
            let isSoftSpiral = safetyService.checkSoftSpiral(message: text)

            // Build strategist prompt with context injection
            var strategistPrompt = Prompts.strategist
                .replacingOccurrences(of: "{{user_name}}", with: profile?.displayName ?? "babe")
                .replacingOccurrences(of: "{{archetype_label}}", with: archetype?.label ?? "Not determined")
                .replacingOccurrences(of: "{{relationship_status}}", with: "Not shared yet")
                .replacingOccurrences(of: "{{current_vibe}}", with: currentVibe?.rawValue ?? "MEDIUM")

            // Inject router context
            strategistPrompt += """

            <router_context>
              Category: \(classification.category.rawValue)
              Urgency: \(classification.urgency.rawValue)
              Reasoning: \(classification.reasoning)
            </router_context>
            """

            // Soft spiral: override strategy to gentle support mode
            if isSoftSpiral {
                strategistPrompt += """

            <soft_spiral_override>
              OVERRIDE: The user is in a soft spiral (emotional numbness, shutdown, dissociation).
              DROP all frameworks, tough love, and Chloe-isms.
              Be "The Anchor." Validate without fixing. Short, grounding sentences.
              End with ONE gentle micro-task ("Can you get a glass of water?" / "Can you take one deep breath for me?").
              Set strategy_selection to "Gentle Support" in internal_thought.
            </soft_spiral_override>
            """
            }

            // Inject behavioral loops (permanent patterns) for long-term strategy
            if let loops = profile?.behavioralLoops, !loops.isEmpty {
                strategistPrompt += """

            <known_patterns>
              These are behavioral patterns detected across previous sessions.
              Use them to call out recurring behaviors when relevant:
              \(loops.map { "- \($0)" }.joined(separator: "\n  "))
            </known_patterns>
            """
            }

            let strategistResponse = try await geminiService.sendStrategistMessage(
                messages: messages,
                systemPrompt: strategistPrompt,
                userFacts: userFacts,
                lastSummary: lastSummary,
                insight: insight,
                temperature: 0.7,
                userId: nil,
                conversationId: nil,
                attempt: 1
            )

            // Phase 3: Render
            let routerMetadata = RouterMetadata(
                internalThought: """
                    Vibe: \(strategistResponse.internalThought.userVibe)
                    Analysis: \(strategistResponse.internalThought.manBehaviorAnalysis)
                    Strategy: \(strategistResponse.internalThought.strategySelection)
                    """,
                routerMode: classification.category.rawValue,
                selectedOption: nil
            )

            let chloeMsg = Message(
                conversationId: conversationId,
                role: .chloe,
                text: strategistResponse.response.text,
                routerMetadata: routerMetadata,
                contentType: strategistResponse.response.options != nil ? .optionPair : .text,
                options: strategistResponse.response.options
            )
            messages.append(chloeMsg)
            saveMessages()

            loadingState = .idle

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
                Task { [weak self] in
                    await self?.triggerBackgroundAnalysis()
                }
            }
        } catch let geminiError as GeminiError {
            lastFailedText = text
            loadingState = .idle
            switch geminiError {
            case .rateLimited:
                showError("Chloe needs a moment to recharge. Try again in a minute.")
                trackSignal("chat.error.rateLimited")
            case .noConnection:
                showError("No internet connection. Please check your network and try again.", autoDismiss: false)
                trackSignal("chat.error.noConnection")
            case .timeout:
                showError("Chloe is taking too long to respond. Tap to retry.")
                trackSignal("chat.error.timeout")
            default:
                showError("Message failed to send. Tap to retry.")
                trackSignal("chat.error.other")
            }
        } catch {
            lastFailedText = text
            loadingState = .idle
            showError("Message failed to send. Tap to retry.")
            trackSignal("chat.error.unknown")
        }

        isTyping = false
        loadingState = .idle
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

    /// Show an error message as an inline banner. Auto-clears after 5 seconds
    /// unless `autoDismiss` is false (used for persistent states like offline).
    private func showError(_ message: String, autoDismiss: Bool = true) {
        errorDismissTask?.cancel()
        errorMessage = message
        if autoDismiss {
            errorDismissTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                if self?.errorMessage == message {
                    withAnimation { self?.errorMessage = nil }
                }
            }
        }
    }

    func startNewChat() {
        conversationId = UUID().uuidString.lowercased()
        messages = []
        inputText = ""
        errorMessage = nil
        errorDismissTask?.cancel()
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
        do {
            try storageService.saveMessages(messages, forConversation: id)
        } catch {
            #if DEBUG
            print("[ChatViewModel] Failed to save messages: \(error.localizedDescription)")
            #endif
        }

        // Create or update conversation metadata
        var convo = storageService.loadConversation(id: id)
            ?? Conversation(id: id, title: "New Conversation")
        convo.updatedAt = Date()
        do {
            try storageService.saveConversation(convo)
        } catch {
            #if DEBUG
            print("[ChatViewModel] Failed to save conversation: \(error.localizedDescription)")
            #endif
        }

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

                // Push behavioral loops to insight queue for Chloe to call out (short-term)
                for loop in result.behavioralLoops {
                    storageService.pushInsight("Behavioral pattern: \(loop)")
                }

                // Persist behavioral loops permanently for long-term strategy
                if !result.behavioralLoops.isEmpty {
                    storageService.addBehavioralLoops(result.behavioralLoops)
                }
            }
        } catch {
            // Background analysis failures are silent
            #if DEBUG
            print("[ChatViewModel] Background analysis failed: \(error.localizedDescription)")
            #endif
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
