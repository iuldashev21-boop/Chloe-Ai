import Foundation

class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Profile

    func saveProfile(_ profile: Profile) throws {
        let data = try encoder.encode(profile)
        defaults.set(data, forKey: "profile")
    }

    func loadProfile() -> Profile? {
        guard let data = defaults.data(forKey: "profile") else { return nil }
        return try? decoder.decode(Profile.self, from: data)
    }

    // MARK: - Profile Image

    func saveProfileImage(_ imageData: Data) throws -> String {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent("profile_image.jpg")
        try imageData.write(to: url)
        return url.path
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
    }

    func loadConversations() -> [Conversation] {
        guard let data = defaults.data(forKey: "conversations") else { return [] }
        return (try? decoder.decode([Conversation].self, from: data)) ?? []
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

    // MARK: - Journal

    func saveJournalEntries(_ entries: [JournalEntry]) throws {
        let data = try encoder.encode(entries)
        defaults.set(data, forKey: "journal_entries")
    }

    func loadJournalEntries() -> [JournalEntry] {
        guard let data = defaults.data(forKey: "journal_entries") else { return [] }
        return (try? decoder.decode([JournalEntry].self, from: data)) ?? []
    }

    // MARK: - Goals

    func saveGoals(_ goals: [Goal]) throws {
        let data = try encoder.encode(goals)
        defaults.set(data, forKey: "goals")
    }

    func loadGoals() -> [Goal] {
        guard let data = defaults.data(forKey: "goals") else { return [] }
        return (try? decoder.decode([Goal].self, from: data)) ?? []
    }

    // MARK: - Affirmations

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        let data = try encoder.encode(affirmations)
        defaults.set(data, forKey: "affirmations")
    }

    func loadAffirmations() -> [Affirmation] {
        guard let data = defaults.data(forKey: "affirmations") else { return [] }
        return (try? decoder.decode([Affirmation].self, from: data)) ?? []
    }

    // MARK: - Vision Board

    func saveVisionItems(_ items: [VisionItem]) throws {
        let data = try encoder.encode(items)
        defaults.set(data, forKey: "vision_items")
    }

    func loadVisionItems() -> [VisionItem] {
        guard let data = defaults.data(forKey: "vision_items") else { return [] }
        return (try? decoder.decode([VisionItem].self, from: data)) ?? []
    }

    // MARK: - User Facts (separate from Profile)

    func saveUserFacts(_ facts: [UserFact]) throws {
        let data = try encoder.encode(facts)
        defaults.set(data, forKey: "user_facts")
    }

    func loadUserFacts() -> [UserFact] {
        guard let data = defaults.data(forKey: "user_facts") else { return [] }
        return (try? decoder.decode([UserFact].self, from: data)) ?? []
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

    private struct StoredInsight: Codable {
        let text: String
        let createdAt: Date
    }

    func pushInsight(_ insight: String) {
        var queue = loadInsightQueue()
        // Dedup: skip if a similar insight already exists (case-insensitive substring)
        let lowered = insight.lowercased()
        let isDuplicate = queue.contains { lowered.contains($0.text.lowercased()) || $0.text.lowercased().contains(lowered) }
        guard !isDuplicate else { return }
        queue.append(StoredInsight(text: insight, createdAt: Date()))
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

    private func loadInsightQueue() -> [StoredInsight] {
        guard let data = defaults.data(forKey: "insight_queue") else { return [] }
        return (try? decoder.decode([StoredInsight].self, from: data)) ?? []
    }

    private func saveInsightQueue(_ queue: [StoredInsight]) {
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

        if storedWeekStart == nil || storedWeekStart! < weekStart {
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
    }
}
