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

    // MARK: - Thread Safety

    /// Serializes all reads/writes to caches and UserDefaults to prevent TOCTOU races.
    /// Multiple ViewModels can call StorageService concurrently; this lock ensures
    /// read-modify-write sequences (e.g. saveConversation, pushInsight) are atomic.
    private let lock = NSLock()

    // MARK: - In-Memory Caches (read-heavy, write-light data)

    private var profileCache: Profile?
    private var conversationsCache: [Conversation]?
    private var journalEntriesCache: [JournalEntry]?
    private var goalsCache: [Goal]?
    private var affirmationsCache: [Affirmation]?
    private var visionItemsCache: [VisionItem]?
    private var userFactsCache: [UserFact]?
    private var messagesCache: [String: [Message]] = [:]  // keyed by conversationId

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Clear all in-memory caches (call on memory pressure or sign-out)
    func clearCaches() {
        lock.lock()
        defer { lock.unlock() }
        _clearCaches()
    }

    private func _clearCaches() {
        profileCache = nil
        conversationsCache = nil
        journalEntriesCache = nil
        goalsCache = nil
        affirmationsCache = nil
        visionItemsCache = nil
        userFactsCache = nil
        messagesCache.removeAll()
    }

    // MARK: - Profile

    func saveProfile(_ profile: Profile) throws {
        lock.lock()
        defer { lock.unlock() }
        try _saveProfile(profile)
    }

    func loadProfile() -> Profile? {
        lock.lock()
        defer { lock.unlock() }
        return _loadProfile()
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveProfile(_ profile: Profile) throws {
        let data = try encoder.encode(profile)
        defaults.set(data, forKey: "profile")
        profileCache = profile
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadProfile() -> Profile? {
        if let cached = profileCache { return cached }
        guard let data = defaults.data(forKey: "profile") else { return nil }
        do {
            let profile = try decoder.decode(Profile.self, from: data)
            profileCache = profile
            return profile
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (profile): \(error.localizedDescription)")
            #endif
            return nil
        }
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

    /// Save downloaded chat image data and return local path (used for cloud sync re-download)
    func saveChatImageData(_ data: Data, filename: String) -> String? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
        lock.lock()
        defer { lock.unlock() }
        guard let profile = _loadProfile(),
              let path = profile.profileImageUri else { return nil }
        return FileManager.default.contents(atPath: path)
    }

    func deleteProfileImage() throws {
        lock.lock()
        defer { lock.unlock() }
        guard var profile = _loadProfile(),
              let path = profile.profileImageUri else { return }
        try? FileManager.default.removeItem(atPath: path)
        profile.profileImageUri = nil
        profile.updatedAt = Date()
        try _saveProfile(profile)
    }

    // MARK: - Conversations (metadata only, messages stored separately)

    func saveConversations(_ conversations: [Conversation]) throws {
        lock.lock()
        defer { lock.unlock() }
        try _saveConversations(conversations)
    }

    func loadConversations() -> [Conversation] {
        lock.lock()
        defer { lock.unlock() }
        return _loadConversations()
    }

    func saveConversation(_ conversation: Conversation) throws {
        lock.lock()
        defer { lock.unlock() }
        var conversations = _loadConversations()
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
        try _saveConversations(conversations)
    }

    func loadConversation(id: String) -> Conversation? {
        lock.lock()
        defer { lock.unlock() }
        return _loadConversations().first { $0.id == id }
    }

    func renameConversation(id: String, newTitle: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard var convo = _loadConversations().first(where: { $0.id == id }) else { return }
        convo.title = newTitle
        convo.updatedAt = Date()
        var conversations = _loadConversations()
        if let index = conversations.firstIndex(where: { $0.id == convo.id }) {
            conversations[index] = convo
        } else {
            conversations.append(convo)
        }
        try _saveConversations(conversations)
    }

    func toggleConversationStar(id: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard var convo = _loadConversations().first(where: { $0.id == id }) else { return }
        convo.starred.toggle()
        convo.updatedAt = Date()
        var conversations = _loadConversations()
        if let index = conversations.firstIndex(where: { $0.id == convo.id }) {
            conversations[index] = convo
        } else {
            conversations.append(convo)
        }
        try _saveConversations(conversations)
    }

    func deleteConversation(id: String) {
        lock.lock()
        defer { lock.unlock() }
        defaults.removeObject(forKey: "messages_\(id)")
        messagesCache.removeValue(forKey: id)
        var conversations = _loadConversations()
        conversations.removeAll { $0.id == id }
        try? _saveConversations(conversations)
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveConversations(_ conversations: [Conversation]) throws {
        let data = try encoder.encode(conversations)
        defaults.set(data, forKey: "conversations")
        conversationsCache = conversations
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadConversations() -> [Conversation] {
        if let cached = conversationsCache { return cached }
        guard let data = defaults.data(forKey: "conversations") else { return [] }
        do {
            let conversations = try decoder.decode([Conversation].self, from: data)
            conversationsCache = conversations
            return conversations
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (conversations): \(error.localizedDescription)")
            #endif
            return []  // Return empty but do NOT cache — next save won't overwrite good data
        }
    }

    // MARK: - Messages (stored per conversation)

    func saveMessages(_ messages: [Message], forConversation conversationId: String) throws {
        lock.lock()
        defer { lock.unlock() }
        let data = try encoder.encode(messages)
        defaults.set(data, forKey: "messages_\(conversationId)")
        messagesCache[conversationId] = messages
    }

    func loadMessages(forConversation conversationId: String) -> [Message] {
        lock.lock()
        defer { lock.unlock() }
        return _loadMessages(forConversation: conversationId)
    }

    /// Load the most recent `limit` messages for a conversation (for pagination).
    /// Returns messages in chronological order (oldest first).
    func loadMessages(forConversation conversationId: String, limit: Int) -> [Message] {
        lock.lock()
        defer { lock.unlock() }
        let all = _loadMessages(forConversation: conversationId)
        guard all.count > limit else { return all }
        return Array(all.suffix(limit))
    }

    /// Total message count for a conversation (without decoding all messages).
    func messageCount(forConversation conversationId: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return _loadMessages(forConversation: conversationId).count
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadMessages(forConversation conversationId: String) -> [Message] {
        if let cached = messagesCache[conversationId] { return cached }
        guard let data = defaults.data(forKey: "messages_\(conversationId)") else { return [] }
        do {
            let messages = try decoder.decode([Message].self, from: data)
            messagesCache[conversationId] = messages
            return messages
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (messages_\(conversationId)): \(error.localizedDescription)")
            #endif
            return []
        }
    }

    // MARK: - Journal

    func saveJournalEntries(_ entries: [JournalEntry]) throws {
        lock.lock()
        defer { lock.unlock() }
        try _saveJournalEntries(entries)
    }

    func loadJournalEntries() -> [JournalEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _loadJournalEntries()
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveJournalEntries(_ entries: [JournalEntry]) throws {
        let data = try encoder.encode(entries)
        defaults.set(data, forKey: "journal_entries")
        journalEntriesCache = entries
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadJournalEntries() -> [JournalEntry] {
        if let cached = journalEntriesCache { return cached }
        guard let data = defaults.data(forKey: "journal_entries") else { return [] }
        do {
            let entries = try decoder.decode([JournalEntry].self, from: data)
            journalEntriesCache = entries
            return entries
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (journal_entries): \(error.localizedDescription)")
            #endif
            return []
        }
    }

    // MARK: - Goals

    func saveGoals(_ goals: [Goal]) throws {
        lock.lock()
        defer { lock.unlock() }
        try _saveGoals(goals)
    }

    func loadGoals() -> [Goal] {
        lock.lock()
        defer { lock.unlock() }
        return _loadGoals()
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveGoals(_ goals: [Goal]) throws {
        let data = try encoder.encode(goals)
        defaults.set(data, forKey: "goals")
        goalsCache = goals
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadGoals() -> [Goal] {
        if let cached = goalsCache { return cached }
        guard let data = defaults.data(forKey: "goals") else { return [] }
        do {
            let goals = try decoder.decode([Goal].self, from: data)
            goalsCache = goals
            return goals
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (goals): \(error.localizedDescription)")
            #endif
            return []
        }
    }

    // MARK: - Affirmations

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        lock.lock()
        defer { lock.unlock() }
        try _saveAffirmations(affirmations)
    }

    func loadAffirmations() -> [Affirmation] {
        lock.lock()
        defer { lock.unlock() }
        return _loadAffirmations()
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveAffirmations(_ affirmations: [Affirmation]) throws {
        let data = try encoder.encode(affirmations)
        defaults.set(data, forKey: "affirmations")
        affirmationsCache = affirmations
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadAffirmations() -> [Affirmation] {
        if let cached = affirmationsCache { return cached }
        guard let data = defaults.data(forKey: "affirmations") else { return [] }
        do {
            let affirmations = try decoder.decode([Affirmation].self, from: data)
            affirmationsCache = affirmations
            return affirmations
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (affirmations): \(error.localizedDescription)")
            #endif
            return []
        }
    }

    // MARK: - Vision Board

    func saveVisionItems(_ items: [VisionItem]) throws {
        lock.lock()
        defer { lock.unlock() }
        try _saveVisionItems(items)
    }

    func loadVisionItems() -> [VisionItem] {
        lock.lock()
        defer { lock.unlock() }
        return _loadVisionItems()
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveVisionItems(_ items: [VisionItem]) throws {
        let data = try encoder.encode(items)
        defaults.set(data, forKey: "vision_items")
        visionItemsCache = items
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadVisionItems() -> [VisionItem] {
        if let cached = visionItemsCache { return cached }
        guard let data = defaults.data(forKey: "vision_items") else { return [] }
        do {
            let items = try decoder.decode([VisionItem].self, from: data)
            visionItemsCache = items
            return items
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (vision_items): \(error.localizedDescription)")
            #endif
            return []
        }
    }

    // MARK: - User Facts (separate from Profile)

    func saveUserFacts(_ facts: [UserFact]) throws {
        lock.lock()
        defer { lock.unlock() }
        try _saveUserFacts(facts)
    }

    func loadUserFacts() -> [UserFact] {
        lock.lock()
        defer { lock.unlock() }
        return _loadUserFacts()
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveUserFacts(_ facts: [UserFact]) throws {
        let data = try encoder.encode(facts)
        defaults.set(data, forKey: "user_facts")
        userFactsCache = facts
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadUserFacts() -> [UserFact] {
        if let cached = userFactsCache { return cached }
        guard let data = defaults.data(forKey: "user_facts") else { return [] }
        do {
            let facts = try decoder.decode([UserFact].self, from: data)
            userFactsCache = facts
            return facts
        } catch {
            #if DEBUG
            print("[StorageService] DECODE ERROR (user_facts): \(error.localizedDescription)")
            #endif
            return []
        }
    }

    // MARK: - Latest Vibe

    func saveLatestVibe(_ vibe: VibeScore) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(vibe.rawValue, forKey: "latest_vibe")
    }

    func loadLatestVibe() -> VibeScore? {
        lock.lock()
        defer { lock.unlock() }
        guard let raw = defaults.string(forKey: "latest_vibe") else { return nil }
        return VibeScore(rawValue: raw)
    }

    // MARK: - Daily Usage

    func saveDailyUsage(_ usage: DailyUsage) throws {
        lock.lock()
        defer { lock.unlock() }
        let data = try encoder.encode(usage)
        defaults.set(data, forKey: "daily_usage")
    }

    func loadDailyUsage() -> DailyUsage {
        lock.lock()
        defer { lock.unlock() }
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
        lock.lock()
        defer { lock.unlock() }
        defaults.set(count, forKey: "messages_since_analysis")
    }

    func loadMessagesSinceAnalysis() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return defaults.integer(forKey: "messages_since_analysis")
    }

    // MARK: - Streak

    func saveStreak(_ streak: GlowUpStreak) {
        lock.lock()
        defer { lock.unlock() }
        if let data = try? encoder.encode(streak) {
            defaults.set(data, forKey: "glow_up_streak")
        }
    }

    func loadStreak() -> GlowUpStreak {
        lock.lock()
        defer { lock.unlock() }
        guard let data = defaults.data(forKey: "glow_up_streak"),
              let streak = try? decoder.decode(GlowUpStreak.self, from: data) else {
            return GlowUpStreak()
        }
        return streak
    }

    // MARK: - Latest Summary

    func saveLatestSummary(_ summary: String) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(summary, forKey: "latest_summary")
    }

    func loadLatestSummary() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return defaults.string(forKey: "latest_summary")
    }

    // MARK: - Insight Queue (FIFO with dedup + expiry)

    func pushInsight(_ insight: String) {
        lock.lock()
        defer { lock.unlock() }
        var queue = _loadInsightQueue()
        let lowered = insight.lowercased()
        let isDuplicate = queue.contains { lowered.contains($0.text.lowercased()) || $0.text.lowercased().contains(lowered) }
        guard !isDuplicate else { return }
        queue.append(InsightEntry(text: insight, createdAt: Date()))
        // Cap at 50 entries — drop oldest
        if queue.count > 50 {
            queue = Array(queue.suffix(50))
        }
        _saveInsightQueue(queue)
    }

    func popInsight() -> String? {
        lock.lock()
        defer { lock.unlock() }
        var queue = _loadInsightQueue()
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
            _saveInsightQueue(queue)
            return nil
        }
        let oldest = queue.removeFirst()
        _saveInsightQueue(queue)
        return oldest.text
    }

    /// Load raw insight entries (for cloud sync)
    func loadInsightEntries() -> [InsightEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _loadInsightQueue()
    }

    /// Replace insight queue from cloud data (for sync)
    func replaceInsightEntries(_ entries: [InsightEntry]) {
        lock.lock()
        defer { lock.unlock() }
        _saveInsightQueue(entries)
    }

    /// Unlocked load — caller must hold `lock`.
    private func _loadInsightQueue() -> [InsightEntry] {
        guard let data = defaults.data(forKey: "insight_queue") else { return [] }
        return (try? decoder.decode([InsightEntry].self, from: data)) ?? []
    }

    /// Unlocked save — caller must hold `lock`.
    private func _saveInsightQueue(_ queue: [InsightEntry]) {
        if let data = try? encoder.encode(queue) {
            defaults.set(data, forKey: "insight_queue")
        }
    }

    // MARK: - Notification Rate Limiting (generic notifications only)

    func incrementGenericNotificationCount() {
        lock.lock()
        defer { lock.unlock() }
        _resetNotificationWeekIfNeeded()
        let count = defaults.integer(forKey: "generic_notif_count")
        defaults.set(count + 1, forKey: "generic_notif_count")
    }

    func getGenericNotificationCountThisWeek() -> Int {
        lock.lock()
        defer { lock.unlock() }
        _resetNotificationWeekIfNeeded()
        return defaults.integer(forKey: "generic_notif_count")
    }

    func canSendGenericNotification() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        _resetNotificationWeekIfNeeded()
        return defaults.integer(forKey: "generic_notif_count") < 3
    }

    /// Unlocked — caller must hold `lock`.
    private func _resetNotificationWeekIfNeeded() {
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
        lock.lock()
        defer { lock.unlock() }
        defaults.set(true, forKey: "notification_priming_shown")
    }

    func hasShownNotificationPriming() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return defaults.bool(forKey: "notification_priming_shown")
    }

    func setNotificationDeniedAfterPriming() {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(true, forKey: "notification_denied_after_priming")
    }

    func wasNotificationDeniedAfterPriming() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return defaults.bool(forKey: "notification_denied_after_priming")
    }

    // MARK: - Clear All

    func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        // Clear per-conversation message keys first
        let conversations = _loadConversations()
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
        _clearCaches()
    }
}

// MARK: - Protocol Conformance

extension StorageService: StorageServiceProtocol {}
