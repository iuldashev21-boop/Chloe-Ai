import Foundation
import UIKit

// MARK: - StorageServiceProtocol

/// Protocol abstracting StorageService's public API for dependency injection and testing.
protocol StorageServiceProtocol: AnyObject {

    // Profile
    func saveProfile(_ profile: Profile) throws
    func loadProfile() -> Profile?

    // Chat Images
    func saveChatImage(_ image: UIImage) -> String?
    func saveChatImageData(_ data: Data, filename: String) -> String?

    // Profile Image
    func saveProfileImage(_ imageData: Data) throws -> String
    func loadProfileImage() -> Data?
    func deleteProfileImage() throws

    // Vision Image
    func saveVisionImage(_ data: Data, itemId: String) -> String?

    // Conversations
    func saveConversations(_ conversations: [Conversation]) throws
    func loadConversations() -> [Conversation]
    func saveConversation(_ conversation: Conversation) throws
    func loadConversation(id: String) -> Conversation?
    func renameConversation(id: String, newTitle: String) throws
    func toggleConversationStar(id: String) throws
    func deleteConversation(id: String)

    // Messages
    func saveMessages(_ messages: [Message], forConversation conversationId: String) throws
    func loadMessages(forConversation conversationId: String) -> [Message]
    func loadMessages(forConversation conversationId: String, limit: Int) -> [Message]
    func messageCount(forConversation conversationId: String) -> Int

    // Journal
    func saveJournalEntries(_ entries: [JournalEntry]) throws
    func loadJournalEntries() -> [JournalEntry]

    // Goals
    func saveGoals(_ goals: [Goal]) throws
    func loadGoals() -> [Goal]

    // Affirmations
    func saveAffirmations(_ affirmations: [Affirmation]) throws
    func loadAffirmations() -> [Affirmation]

    // Vision Board
    func saveVisionItems(_ items: [VisionItem]) throws
    func loadVisionItems() -> [VisionItem]

    // User Facts
    func saveUserFacts(_ facts: [UserFact]) throws
    func loadUserFacts() -> [UserFact]

    // Latest Vibe
    func saveLatestVibe(_ vibe: VibeScore)
    func loadLatestVibe() -> VibeScore?

    // Daily Usage
    func saveDailyUsage(_ usage: DailyUsage) throws
    func loadDailyUsage() -> DailyUsage

    // Messages Since Analysis
    func saveMessagesSinceAnalysis(_ count: Int)
    func loadMessagesSinceAnalysis() -> Int

    // Streak
    func saveStreak(_ streak: GlowUpStreak)
    func loadStreak() -> GlowUpStreak

    // Latest Summary
    func saveLatestSummary(_ summary: String)
    func loadLatestSummary() -> String?

    // Insight Queue
    func pushInsight(_ insight: String)
    func popInsight() -> String?
    func loadInsightEntries() -> [InsightEntry]
    func replaceInsightEntries(_ entries: [InsightEntry])

    // Notification Rate Limiting
    func incrementGenericNotificationCount()
    func getGenericNotificationCountThisWeek() -> Int
    func canSendGenericNotification() -> Bool

    // Notification Permission Priming
    func setNotificationPrimingShown()
    func hasShownNotificationPriming() -> Bool
    func setNotificationDeniedAfterPriming()
    func wasNotificationDeniedAfterPriming() -> Bool

    // Clear All
    func clearAll()
}

// MARK: - GeminiServiceProtocol

/// Protocol abstracting GeminiService's public API for dependency injection and testing.
protocol GeminiServiceProtocol: AnyObject {

    func analyzeConversation(
        messages: [Message],
        userFacts: [String],
        lastSummary: String?,
        currentVibe: VibeScore?,
        displayName: String?
    ) async throws -> AnalystResult

    func sendStrategistMessage(
        messages: [Message],
        systemPrompt: String,
        userFacts: [String],
        lastSummary: String?,
        insight: String?,
        temperature: Double,
        userId: String?,
        conversationId: String?,
        attempt: Int
    ) async throws -> StrategistResponse

    func classifyMessage(
        message: String,
        systemPrompt: String,
        attempt: Int
    ) async throws -> RouterClassification

    func generateAffirmation(
        displayName: String,
        preferences: OnboardingPreferences?,
        archetype: UserArchetype?
    ) async throws -> String

    func generateTitle(for messageText: String) async throws -> String
}

// MARK: - SafetyServiceProtocol

/// Protocol abstracting SafetyService's public API for dependency injection and testing.
protocol SafetyServiceProtocol: AnyObject {
    func checkSoftSpiral(message: String) -> Bool
    func checkSafety(message: String) -> SafetyCheckResult
    func getCrisisResponse(for crisisType: CrisisType) -> String
}

// MARK: - SyncDataServiceProtocol

/// Protocol abstracting SyncDataService's public API for dependency injection and testing.
protocol SyncDataServiceProtocol: AnyObject {

    // Sync Status
    var syncStatus: SyncStatus { get }
    func retryPendingSync() async

    // Cloud Sync
    func pushAllToCloud() async
    func syncFromCloud() async

    // Profile
    func saveProfile(_ profile: Profile) throws
    func loadProfile() -> Profile?
    func addBehavioralLoops(_ newLoops: [String])

    // Chat Images
    func saveChatImage(_ image: UIImage) -> String?

    // Profile Image
    func saveProfileImage(_ imageData: Data) throws -> String
    func loadProfileImage() -> Data?
    func deleteProfileImage() throws

    // Conversations
    func saveConversations(_ conversations: [Conversation]) throws
    func loadConversations() -> [Conversation]
    func saveConversation(_ conversation: Conversation) throws
    func loadConversation(id: String) -> Conversation?
    func renameConversation(id: String, newTitle: String) throws
    func toggleConversationStar(id: String) throws
    @discardableResult
    func deleteConversation(id: String) -> Bool

    // Messages
    func saveMessages(_ messages: [Message], forConversation conversationId: String) throws
    func loadMessages(forConversation conversationId: String) -> [Message]
    func loadMessages(forConversation conversationId: String, limit: Int) -> [Message]
    func messageCount(forConversation conversationId: String) -> Int

    // Journal
    func saveJournalEntries(_ entries: [JournalEntry]) throws
    func loadJournalEntries() -> [JournalEntry]
    @discardableResult
    func deleteJournalEntry(id: String) -> Bool

    // Goals
    func saveGoals(_ goals: [Goal]) throws
    func loadGoals() -> [Goal]
    @discardableResult
    func deleteGoal(id: String) -> Bool

    // Affirmations
    func saveAffirmations(_ affirmations: [Affirmation]) throws
    func loadAffirmations() -> [Affirmation]
    @discardableResult
    func deleteAffirmation(id: String) -> Bool

    // Vision Board
    func saveVisionItems(_ items: [VisionItem]) throws
    func loadVisionItems() -> [VisionItem]
    @discardableResult
    func deleteVisionItem(id: String) -> Bool

    // User Facts
    func saveUserFacts(_ facts: [UserFact]) throws
    func loadUserFacts() -> [UserFact]

    // Latest Vibe
    func saveLatestVibe(_ vibe: VibeScore)
    func loadLatestVibe() -> VibeScore?

    // Daily Usage
    func saveDailyUsage(_ usage: DailyUsage) throws
    func loadDailyUsage() -> DailyUsage

    // Messages Since Analysis
    func saveMessagesSinceAnalysis(_ count: Int)
    func loadMessagesSinceAnalysis() -> Int

    // Streak
    func saveStreak(_ streak: GlowUpStreak)
    func loadStreak() -> GlowUpStreak

    // Latest Summary
    func saveLatestSummary(_ summary: String)
    func loadLatestSummary() -> String?

    // Insight Queue
    func pushInsight(_ insight: String)
    func popInsight() -> String?

    // Notification Rate Limiting
    func incrementGenericNotificationCount()
    func getGenericNotificationCountThisWeek() -> Int
    func canSendGenericNotification() -> Bool

    // Notification Permission Priming
    func setNotificationPrimingShown()
    func hasShownNotificationPriming() -> Bool
    func setNotificationDeniedAfterPriming()
    func wasNotificationDeniedAfterPriming() -> Bool

    // Clear All
    func clearAll()
    func deleteAccount() async throws
}

// MARK: - ArchetypeServiceProtocol

/// Protocol abstracting ArchetypeService's public API for dependency injection and testing.
protocol ArchetypeServiceProtocol: AnyObject {
    func classify(answers: ArchetypeAnswers) -> UserArchetype
}

// MARK: - AuthServiceProtocol

/// Protocol abstracting the auth-related API of AuthViewModel for dependency injection and testing.
/// Covers authentication state and actions, not UI form fields.
@MainActor
protocol AuthServiceProtocol: AnyObject {
    var authState: AuthState { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var email: String { get }
    var errorMessage: String? { get set }

    func signIn(email: String, password: String) async
    func signUp(email: String, password: String) async
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async
    func resendConfirmationEmail() async
    func cancelEmailConfirmation()
    func sendPasswordReset(email: String) async throws
    func updatePassword(_ newPassword: String) async throws
    func handlePasswordRecovery()
    func signOut()
    func restoreSession()
    @discardableResult
    func checkIfBlocked(_ profile: Profile) -> Bool
}
