import Foundation
import UIKit

/// Shared struct for insight queue entries (used by StorageService + SyncDataService)
struct InsightEntry: Codable {
    let text: String
    let createdAt: Date
}

class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - In-Memory Caches (read-heavy, write-light data)

    private var profileCache: Profile?
    private var conversationsCache: [Conversation]?
    private var journalEntriesCache: [JournalEntry]?
    private var goalsCache: [Goal]?
    private var affirmationsCache: [Affirmation]?
    private var visionItemsCache: [VisionItem]?
    private var userFactsCache: [UserFact]?

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Clear all in-memory caches (call on memory pressure or sign-out)
    func clearCaches() {
        profileCache = nil
        conversationsCache = nil
        journalEntriesCache = nil
        goalsCache = nil
        affirmationsCache = nil
        visionItemsCache = nil
        userFactsCache = nil
    }

    // MARK: - Profile

    func saveProfile(_ profile: Profile) throws {
        let data = try encoder.encode(profile)
        defaults.set(data, forKey: "profile")
        profileCache = profile
    }

    func loadProfile() -> Profile? {
        if let cached = profileCache { return cached }
        guard let data = defaults.data(forKey: "profile") else { return nil }
        let profile = try? decoder.decode(Profile.self, from: data)
        profileCache = profile
        return profile
    }

    // MARK: - Chat Images

    func saveChatImage(_ image: UIImage) -> String? {
        let resized = image.downsampledIfNeeded()
        guard let data = resized.jpegData(compressionQuality: 0.7) else { return nil }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "chat_\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    // MARK: - Profile Image

    func saveProfileImage(_ imageData: Data) throws -> String {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("profile_image.jpg")
        try imageData.write(to: url)
        return url.path
    }

    // MARK: - Vision Image

    /// Save vision image data and return local path (used for cloud sync)
    func saveVisionImage(_ data: Data, itemId: String) -> String? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("vision_\(itemId).jpg")
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    func loadProfileImage() -> Data? {
        guard let profile = loadProfile(),
              let path = profile.profileImageUri else { return nil }
        return FileManager.default.contents(atPath: path)
    }

    func deleteProfileImage() throws {
        guard var profile = loadProfile(),
              let path = profile.profileImageUri else { return }
        try? FileManager.default.removeItem(atPath: path)
        profile.profileImageUri = nil
        profile.updatedAt = Date()
        try saveProfile(profile)
    }

    // MARK: - Conversations (metadata only, messages stored separately)

    func saveConversations(_ conversations: [Conversation]) throws {
        let data = try encoder.encode(conversations)
        defaults.set(data, forKey: "conversations")
        conversationsCache = conversations
    }

    func loadConversations() -> [Conversation] {
        if let cached = conversationsCache { return cached }
        guard let data = defaults.data(forKey: "conversations") else { return [] }
        let conversations = (try? decoder.decode([Conversation].self, from: data)) ?? []
        conversationsCache = conversations
        return conversations
    }

    func saveConversation(_ conversation: Conversation) throws {
        var conversations = loadConversations()
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
        try saveConversations(conversations)
    }

    func loadConversation(id: String) -> Conversation? {
        return loadConversations().first { $0.id == id }
    }

    func renameConversation(id: String, newTitle: String) throws {
        guard var convo = loadConversation(id: id) else { return }
        convo.title = newTitle
        convo.updatedAt = Date()
        try saveConversation(convo)
    }

    func toggleConversationStar(id: String) throws {
        guard var convo = loadConversation(id: id) else { return }
        convo.starred.toggle()
        convo.updatedAt = Date()
        try saveConversation(convo)
    }

    func deleteConversation(id: String) {
        defaults.removeObject(forKey: "messages_\(id)")
        var conversations = loadConversations()
        conversations.removeAll { $0.id == id }
        try? saveConversations(conversations)
    }

    // MARK: - Messages (stored per conversation)

    func saveMessages(_ messages: [Message], forConversation conversationId: String) throws {
        let data = try encoder.encode(messages)
        defaults.set(data, forKey: "messages_\(conversationId)")
    }

    func loadMessages(forConversation conversationId: String) -> [Message] {
        guard let data = defaults.data(forKey: "messages_\(conversationId)") else { return [] }
        return (try? decoder.decode([Message].self, from: data)) ?? []
    }

    /// Load the most recent `limit` messages for a conversation (for pagination).
    /// Returns messages in chronological order (oldest first).
    func loadMessages(forConversation conversationId: String, limit: Int) -> [Message] {
        let all = loadMessages(forConversation: conversationId)
        guard all.count > limit else { return all }
        return Array(all.suffix(limit))
    }

    /// Total message count for a conversation (without decoding all messages).
    func messageCount(forConversation conversationId: String) -> Int {
        return loadMessages(forConversation: conversationId).count
    }

    // MARK: - Journal

    func saveJournalEntries(_ entries: [JournalEntry]) throws {
        let data = try encoder.encode(entries)
        defaults.set(data, forKey: "journal_entries")
        journalEntriesCache = entries
    }

    func loadJournalEntries() -> [JournalEntry] {
        if let cached = journalEntriesCache { return cached }
        guard let data = defaults.data(forKey: "journal_entries") else { return [] }
        let entries = (try? decoder.decode([JournalEntry].self, from: data)) ?? []
        journalEntriesCache = entries
        return entries
    }

    // MARK: - Goals

    func saveGoals(_ goals: [Goal]) throws {
        let data = try encoder.encode(goals)
        defaults.set(data, forKey: "goals")
        goalsCache = goals
    }

    func loadGoals() -> [Goal] {
        if let cached = goalsCache { return cached }
        guard let data = defaults.data(forKey: "goals") else { return [] }
        let goals = (try? decoder.decode([Goal].self, from: data)) ?? []
        goalsCache = goals
        return goals
    }

    // MARK: - Affirmations

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        let data = try encoder.encode(affirmations)
        defaults.set(data, forKey: "affirmations")
        affirmationsCache = affirmations
    }

    func loadAffirmations() -> [Affirmation] {
        if let cached = affirmationsCache { return cached }
        guard let data = defaults.data(forKey: "affirmations") else { return [] }
        let affirmations = (try? decoder.decode([Affirmation].self, from: data)) ?? []
        affirmationsCache = affirmations
        return affirmations
    }

    // MARK: - Vision Board

    func saveVisionItems(_ items: [VisionItem]) throws {
        let data = try encoder.encode(items)
        defaults.set(data, forKey: "vision_items")
        visionItemsCache = items
    }

    func loadVisionItems() -> [VisionItem] {
        if let cached = visionItemsCache { return cached }
        guard let data = defaults.data(forKey: "vision_items") else { return [] }
        let items = (try? decoder.decode([VisionItem].self, from: data)) ?? []
        visionItemsCache = items
        return items
    }

    // MARK: - User Facts (separate from Profile)

    func saveUserFacts(_ facts: [UserFact]) throws {
        let data = try encoder.encode(facts)
        defaults.set(data, forKey: "user_facts")
        userFactsCache = facts
    }

    func loadUserFacts() -> [UserFact] {
        if let cached = userFactsCache { return cached }
        guard let data = defaults.data(forKey: "user_facts") else { return [] }
        let facts = (try? decoder.decode([UserFact].self, from: data)) ?? []
        userFactsCache = facts
        return facts
    }

    // MARK: - Latest Vibe

    func saveLatestVibe(_ vibe: VibeScore) {
        defaults.set(vibe.rawValue, forKey: "latest_vibe")
    }

    func loadLatestVibe() -> VibeScore? {
        guard let raw = defaults.string(forKey: "latest_vibe") else { return nil }
        return VibeScore(rawValue: raw)
    }

    // MARK: - Daily Usage

    func saveDailyUsage(_ usage: DailyUsage) throws {
        let data = try encoder.encode(usage)
        defaults.set(data, forKey: "daily_usage")
    }

    func loadDailyUsage() -> DailyUsage {
        guard let data = defaults.data(forKey: "daily_usage"),
              let usage = try? decoder.decode(DailyUsage.self, from: data) else {
            return DailyUsage(date: DailyUsage.todayKey(), messageCount: 0)
        }
        // Reset if it's a new day
        if usage.date != DailyUsage.todayKey() {
            return DailyUsage(date: DailyUsage.todayKey(), messageCount: 0)
        }
        return usage
    }

    // MARK: - Messages Since Analysis

    func saveMessagesSinceAnalysis(_ count: Int) {
        defaults.set(count, forKey: "messages_since_analysis")
    }

    func loadMessagesSinceAnalysis() -> Int {
        return defaults.integer(forKey: "messages_since_analysis")
    }

    // MARK: - Streak

    func saveStreak(_ streak: GlowUpStreak) {
        if let data = try? encoder.encode(streak) {
            defaults.set(data, forKey: "glow_up_streak")
        }
    }

    func loadStreak() -> GlowUpStreak {
        guard let data = defaults.data(forKey: "glow_up_streak"),
              let streak = try? decoder.decode(GlowUpStreak.self, from: data) else {
            return GlowUpStreak()
        }
        return streak
    }

    // MARK: - Latest Summary

    func saveLatestSummary(_ summary: String) {
        defaults.set(summary, forKey: "latest_summary")
    }

    func loadLatestSummary() -> String? {
        return defaults.string(forKey: "latest_summary")
    }

    // MARK: - Insight Queue (FIFO with dedup + expiry)

    func pushInsight(_ insight: String) {
        var queue = loadInsightQueue()
        // Dedup: skip if a similar insight already exists (case-insensitive substring)
        let lowered = insight.lowercased()
        let isDuplicate = queue.contains { lowered.contains($0.text.lowercased()) || $0.text.lowercased().contains(lowered) }
        guard !isDuplicate else { return }
        queue.append(InsightEntry(text: insight, createdAt: Date()))
        saveInsightQueue(queue)
    }

    func popInsight() -> String? {
        var queue = loadInsightQueue()
        let expiryDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        // Skip and discard expired insights
        while let first = queue.first {
            if first.createdAt < expiryDate {
                queue.removeFirst()
            } else {
                break
            }
        }
        guard !queue.isEmpty else {
            saveInsightQueue(queue)
            return nil
        }
        let oldest = queue.removeFirst()
        saveInsightQueue(queue)
        return oldest.text
    }

    /// Load raw insight entries (for cloud sync)
    func loadInsightEntries() -> [InsightEntry] {
        return loadInsightQueue()
    }

    /// Replace insight queue from cloud data (for sync)
    func replaceInsightEntries(_ entries: [InsightEntry]) {
        saveInsightQueue(entries)
    }

    private func loadInsightQueue() -> [InsightEntry] {
        guard let data = defaults.data(forKey: "insight_queue") else { return [] }
        return (try? decoder.decode([InsightEntry].self, from: data)) ?? []
    }

    private func saveInsightQueue(_ queue: [InsightEntry]) {
        if let data = try? encoder.encode(queue) {
            defaults.set(data, forKey: "insight_queue")
        }
    }

    // MARK: - Notification Rate Limiting (generic notifications only)

    func incrementGenericNotificationCount() {
        resetNotificationWeekIfNeeded()
        let count = defaults.integer(forKey: "generic_notif_count")
        defaults.set(count + 1, forKey: "generic_notif_count")
    }

    func getGenericNotificationCountThisWeek() -> Int {
        resetNotificationWeekIfNeeded()
        return defaults.integer(forKey: "generic_notif_count")
    }

    func canSendGenericNotification() -> Bool {
        return getGenericNotificationCountThisWeek() < 3
    }

    private func resetNotificationWeekIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let storedWeekStart = defaults.object(forKey: "notif_week_start") as? Date

        if storedWeekStart.map({ $0 < weekStart }) ?? true {
            defaults.set(weekStart, forKey: "notif_week_start")
            defaults.set(0, forKey: "generic_notif_count")
        }
    }

    // MARK: - Notification Permission Priming

    func setNotificationPrimingShown() {
        defaults.set(true, forKey: "notification_priming_shown")
    }

    func hasShownNotificationPriming() -> Bool {
        return defaults.bool(forKey: "notification_priming_shown")
    }

    func setNotificationDeniedAfterPriming() {
        defaults.set(true, forKey: "notification_denied_after_priming")
    }

    func wasNotificationDeniedAfterPriming() -> Bool {
        return defaults.bool(forKey: "notification_denied_after_priming")
    }

    // MARK: - Clear All

    func clearAll() {
        // Clear per-conversation message keys first
        let conversations = loadConversations()
        for convo in conversations {
            defaults.removeObject(forKey: "messages_\(convo.id)")
        }

        let keys = [
            "profile", "conversations", "journal_entries", "goals",
            "affirmations", "vision_items", "user_facts", "latest_vibe",
            "daily_usage", "messages_since_analysis",
            "glow_up_streak", "latest_summary", "insight_queue",
            "generic_notif_count", "notif_week_start",
            "notification_priming_shown", "notification_denied_after_priming",
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
        clearCaches()
    }
}

// MARK: - Protocol Conformance

extension StorageService: StorageServiceProtocol {}
