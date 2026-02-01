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
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}
