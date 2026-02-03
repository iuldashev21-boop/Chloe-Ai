import Foundation

#if DEBUG
/// Handles launch arguments for UI testing
enum UITestSupport {

    // MARK: - Check if UI Testing

    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting") ||
        ProcessInfo.processInfo.environment["UITEST_MODE"] == "1"
    }

    // MARK: - Auth & Onboarding Flags

    static var shouldSkipAuth: Bool {
        ProcessInfo.processInfo.arguments.contains("--skip-auth")
    }

    static var shouldSkipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("--skip-onboarding")
    }

    static var shouldResetOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-onboarding")
    }

    static var shouldResetState: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-state")
    }

    static var shouldStartAtNameStep: Bool {
        ProcessInfo.processInfo.arguments.contains("--start-at-name-step")
    }

    static var shouldStartAtQuiz: Bool {
        ProcessInfo.processInfo.arguments.contains("--start-at-quiz")
    }

    static var shouldShowAtOnboardingComplete: Bool {
        ProcessInfo.processInfo.arguments.contains("--at-onboarding-complete")
    }

    static var shouldShowNotificationPriming: Bool {
        ProcessInfo.processInfo.arguments.contains("--show-notification-priming")
    }

    // MARK: - Data Flags

    static var shouldClearJournal: Bool {
        ProcessInfo.processInfo.arguments.contains("--clear-journal")
    }

    static var shouldClearGoals: Bool {
        ProcessInfo.processInfo.arguments.contains("--clear-goals")
    }

    static var shouldClearVisionBoard: Bool {
        ProcessInfo.processInfo.arguments.contains("--clear-vision-board")
    }

    static var shouldHaveJournalEntries: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-journal-entries")
    }

    static var shouldHaveGoals: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-goals")
    }

    static var shouldHaveCompletedGoal: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-completed-goal")
    }

    static var shouldHaveVisionItems: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-vision-items")
    }

    static var shouldHaveMultipleVisions: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-multiple-visions")
    }

    static var shouldHaveConversationHistory: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-conversation-history")
    }

    static var shouldHaveLargeConversation: Bool {
        ProcessInfo.processInfo.arguments.contains("--large-conversation-100-messages")
    }

    static var shouldHaveActiveStreak: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-active-streak")
    }

    static var shouldHaveExistingSession: Bool {
        ProcessInfo.processInfo.arguments.contains("--with-existing-session")
    }

    // MARK: - Profile Flags

    static var shouldHaveEmptyDisplayName: Bool {
        ProcessInfo.processInfo.arguments.contains("--empty-display-name")
    }

    static var shouldHaveNoArchetype: Bool {
        ProcessInfo.processInfo.arguments.contains("--no-archetype")
    }

    static var shouldBePremiumUser: Bool {
        ProcessInfo.processInfo.arguments.contains("--premium-user")
    }

    // MARK: - Rate Limiting Flags

    static var shouldResetDailyUsage: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-daily-usage")
    }

    static var shouldHaveDailyUsageCount4: Bool {
        ProcessInfo.processInfo.arguments.contains("--daily-usage-count-4")
    }

    static var shouldHaveDailyUsageLimitReached: Bool {
        ProcessInfo.processInfo.arguments.contains("--daily-usage-limit-reached")
    }

    static var shouldSimulateNextDay: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate-next-day")
    }

    // MARK: - Network Flags

    static var shouldSimulateOffline: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate-offline")
    }

    static var shouldSimulateNetworkError: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate-network-error")
    }

    static var shouldSimulateSlowNetwork: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate-slow-network")
    }

    static var shouldSimulateNetworkDropMidSend: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate-network-drop-mid-send")
    }

    // MARK: - Setup Test Data

    static func setupTestEnvironment() {
        guard isUITesting else { return }

        // Reset state if requested
        if shouldResetState {
            SyncDataService.shared.clearAll()
        }

        // Setup auth state
        if shouldSkipAuth || shouldSkipOnboarding || shouldHaveExistingSession {
            setupAuthenticatedUser()
        }

        // Setup onboarding state
        if shouldSkipOnboarding || shouldHaveExistingSession {
            markOnboardingComplete()
        }

        if shouldResetOnboarding {
            resetOnboarding()
        }

        // Setup profile
        if shouldHaveEmptyDisplayName {
            setEmptyDisplayName()
        }

        if shouldHaveNoArchetype {
            clearArchetypeAnswers()
        }

        if shouldBePremiumUser {
            setPremiumUser()
        }

        // Setup data
        if shouldClearJournal {
            clearJournalEntries()
        }

        if shouldClearGoals {
            clearGoals()
        }

        if shouldClearVisionBoard {
            clearVisionBoard()
        }

        if shouldHaveJournalEntries {
            createTestJournalEntries()
        }

        if shouldHaveGoals {
            createTestGoals()
        }

        if shouldHaveCompletedGoal {
            createCompletedGoal()
        }

        if shouldHaveVisionItems || shouldHaveMultipleVisions {
            createTestVisionItems(multiple: shouldHaveMultipleVisions)
        }

        if shouldHaveConversationHistory || shouldHaveLargeConversation {
            createTestConversations(large: shouldHaveLargeConversation)
        }

        if shouldHaveActiveStreak {
            createActiveStreak()
        }

        // Setup rate limiting
        if shouldResetDailyUsage || shouldSimulateNextDay {
            resetDailyUsage()
        }

        if shouldHaveDailyUsageCount4 {
            setDailyUsageCount(4)
        }

        if shouldHaveDailyUsageLimitReached {
            setDailyUsageCount(5) // FREE_DAILY_MESSAGE_LIMIT is 5
        }
    }

    // MARK: - Private Helpers

    private static func setupAuthenticatedUser() {
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        if profile.email.isEmpty {
            profile.email = "uitest@chloe.test"
        }
        if profile.displayName.isEmpty && !shouldHaveEmptyDisplayName {
            profile.displayName = "TestUser"
        }
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
    }

    private static func markOnboardingComplete() {
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        profile.onboardingComplete = true
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
    }

    private static func resetOnboarding() {
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        profile.onboardingComplete = false
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
    }

    private static func setEmptyDisplayName() {
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        profile.displayName = ""
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
    }

    private static func clearArchetypeAnswers() {
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        profile.preferences?.archetypeAnswers = nil
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
    }

    private static func setPremiumUser() {
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        profile.subscriptionTier = .premium
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
    }

    private static func clearJournalEntries() {
        try? SyncDataService.shared.saveJournalEntries([])
    }

    private static func clearGoals() {
        try? SyncDataService.shared.saveGoals([])
    }

    private static func clearVisionBoard() {
        try? SyncDataService.shared.saveVisionItems([])
    }

    private static func createTestJournalEntries() {
        let entries = [
            JournalEntry(title: "Test Entry 1", content: "This is test content 1", mood: "happy"),
            JournalEntry(title: "Test Entry 2", content: "This is test content 2", mood: "calm"),
        ]
        try? SyncDataService.shared.saveJournalEntries(entries)
    }

    private static func createTestGoals() {
        let goals = [
            Goal(title: "Test Goal 1", description: "Description 1"),
            Goal(title: "Test Goal 2", description: nil),
        ]
        try? SyncDataService.shared.saveGoals(goals)
    }

    private static func createCompletedGoal() {
        var goal = Goal(title: "Completed Goal", description: "Already done")
        goal.status = .completed
        let existingGoals = SyncDataService.shared.loadGoals()
        try? SyncDataService.shared.saveGoals(existingGoals + [goal])
    }

    private static func createTestVisionItems(multiple: Bool) {
        var items = [
            VisionItem(title: "Dream Vacation", category: .travel),
        ]
        if multiple {
            items.append(VisionItem(title: "Career Goal", category: .career))
            items.append(VisionItem(title: "Self Care Goal", category: .selfCare))
        }
        try? SyncDataService.shared.saveVisionItems(items)
    }

    private static func createTestConversations(large: Bool) {
        let convoId = UUID().uuidString
        var convo = Conversation(id: convoId, title: "Test Conversation")
        convo.updatedAt = Date()
        try? SyncDataService.shared.saveConversation(convo)

        var messages: [Message] = []
        let count = large ? 100 : 4

        for i in 0..<count {
            let userMsg = Message(conversationId: convoId, role: .user, text: "Test message \(i + 1)")
            let chloeMsg = Message(conversationId: convoId, role: .chloe, text: "Response to message \(i + 1)")
            messages.append(userMsg)
            messages.append(chloeMsg)
        }

        try? SyncDataService.shared.saveMessages(messages, forConversation: convoId)
    }

    private static func createActiveStreak() {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let streak = GlowUpStreak(currentStreak: 5, longestStreak: 10, lastActiveDate: String(today))
        SyncDataService.shared.saveStreak(streak)
    }

    private static func resetDailyUsage() {
        var usage = DailyUsage()
        usage.messageCount = 0
        usage.date = ISO8601DateFormatter().string(from: Date()).prefix(10).description
        try? SyncDataService.shared.saveDailyUsage(usage)
    }

    private static func setDailyUsageCount(_ count: Int) {
        var usage = SyncDataService.shared.loadDailyUsage()
        usage.messageCount = count
        usage.date = ISO8601DateFormatter().string(from: Date()).prefix(10).description
        try? SyncDataService.shared.saveDailyUsage(usage)
    }
}
#endif
