import Foundation
import Supabase

// MARK: - Supabase DTOs (snake_case handled by SDK's encoder/decoder)

/// Maps to the `profiles` table in Supabase
struct SupabaseProfileDTO: Codable {
    let id: String
    var email: String
    var displayName: String
    var onboardingComplete: Bool
    var archetypeAnswers: OnboardingPreferences?
    var subscriptionTier: String
    var subscriptionExpiresAt: Date?
    var profileImageUrl: String?
    var isBlocked: Bool?
    var blockedAt: Date?
    var blockedReason: String?
    var behavioralLoops: [String]?  // Permanent storage of detected behavioral patterns
    var createdAt: Date
    var updatedAt: Date
}

/// Maps to the `user_state` table in Supabase
struct SupabaseUserStateDTO: Codable {
    let userId: String
    var usageDate: String
    var messageCount: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String
    var latestVibe: String?
    var latestSummary: String?
    var messagesSinceAnalysis: Int
    var insightQueue: [InsightEntry]
    var updatedAt: Date
}

/// Maps to the `conversations` table in Supabase
struct SupabaseConversationDTO: Codable {
    let id: String
    var userId: String
    var title: String
    var starred: Bool
    var createdAt: Date
    var updatedAt: Date
}

/// Maps to the `messages` table in Supabase
struct SupabaseMessageDTO: Codable {
    let id: String
    var conversationId: String
    var role: String
    var content: String
    var imageUrl: String?
    var createdAt: Date

    // v2 Agentic fields
    var routerMetadata: RouterMetadata?
    var contentType: String?
}

/// Maps to the `journal_entries` table in Supabase
struct SupabaseJournalEntryDTO: Codable {
    let id: String
    var userId: String
    var title: String
    var content: String
    var mood: String
    var createdAt: Date
}

/// Maps to the `goals` table in Supabase
struct SupabaseGoalDTO: Codable {
    let id: String
    var userId: String
    var title: String
    var description: String?
    var status: String
    var createdAt: Date
    var completedAt: Date?
    var updatedAt: Date
}

/// Maps to the `affirmations` table in Supabase
struct SupabaseAffirmationDTO: Codable {
    let id: String
    var userId: String
    var text: String
    var date: String
    var isSaved: Bool
    var createdAt: Date
}

/// Maps to the `vision_board_items` table in Supabase
struct SupabaseVisionItemDTO: Codable {
    let id: String
    var userId: String
    var title: String
    var category: String
    var imageUrl: String?
    var createdAt: Date
    var updatedAt: Date
}

/// Maps to the `user_facts` table in Supabase
struct SupabaseUserFactDTO: Codable {
    let id: String
    var userId: String
    var fact: String
    var category: String
    var sourceType: String
    var sourceId: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - SupabaseDataService

class SupabaseDataService {
    static let shared = SupabaseDataService()

    private init() {}

    /// Current authenticated user ID, or nil if not signed in
    var currentUserId: String? {
        supabase.auth.currentSession?.user.id.uuidString
    }

    // MARK: - Profile

    func upsertProfile(_ profile: Profile) async throws {
        guard let userId = currentUserId else { return }

        let dto = SupabaseProfileDTO(
            id: userId,
            email: profile.email,
            displayName: profile.displayName,
            onboardingComplete: profile.onboardingComplete,
            archetypeAnswers: profile.preferences,
            subscriptionTier: profile.subscriptionTier.rawValue,
            subscriptionExpiresAt: profile.subscriptionExpiresAt,
            profileImageUrl: profile.profileImageUri,
            isBlocked: profile.isBlocked,
            blockedAt: profile.blockedAt,
            blockedReason: profile.blockedReason,
            behavioralLoops: profile.behavioralLoops,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )

        try await supabase.from("profiles")
            .upsert(dto)
            .execute()
    }

    func fetchProfile() async throws -> Profile? {
        guard let userId = currentUserId else { return nil }

        let dto: SupabaseProfileDTO = try await supabase.from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return Profile(
            id: dto.id,
            email: dto.email,
            displayName: dto.displayName,
            onboardingComplete: dto.onboardingComplete,
            preferences: dto.archetypeAnswers,
            subscriptionTier: SubscriptionTier(rawValue: dto.subscriptionTier) ?? .free,
            subscriptionExpiresAt: dto.subscriptionExpiresAt,
            profileImageUri: dto.profileImageUrl,
            isBlocked: dto.isBlocked ?? false,
            blockedAt: dto.blockedAt,
            blockedReason: dto.blockedReason,
            behavioralLoops: dto.behavioralLoops,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
    }

    // MARK: - User State

    func upsertUserState(
        usage: DailyUsage,
        streak: GlowUpStreak,
        vibe: VibeScore?,
        summary: String?,
        messagesSinceAnalysis: Int,
        insightQueue: [InsightEntry]
    ) async throws {
        guard let userId = currentUserId else { return }

        let dto = SupabaseUserStateDTO(
            userId: userId,
            usageDate: usage.date,
            messageCount: usage.messageCount,
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            lastActiveDate: streak.lastActiveDate,
            latestVibe: vibe?.rawValue,
            latestSummary: summary,
            messagesSinceAnalysis: messagesSinceAnalysis,
            insightQueue: insightQueue,
            updatedAt: Date()
        )

        try await supabase.from("user_state")
            .upsert(dto)
            .execute()
    }

    func fetchUserState() async throws -> SupabaseUserStateDTO? {
        guard let userId = currentUserId else { return nil }

        let dto: SupabaseUserStateDTO = try await supabase.from("user_state")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value

        return dto
    }

    // MARK: - Conversations

    func upsertConversation(_ conversation: Conversation) async throws {
        guard let userId = currentUserId else { return }

        let dto = SupabaseConversationDTO(
            id: conversation.id,
            userId: userId,
            title: conversation.title,
            starred: conversation.starred,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt
        )

        try await supabase.from("conversations")
            .upsert(dto)
            .execute()
    }

    func fetchConversations() async throws -> [Conversation] {
        guard let userId = currentUserId else { return [] }

        let dtos: [SupabaseConversationDTO] = try await supabase.from("conversations")
            .select()
            .eq("user_id", value: userId)
            .order("updated_at", ascending: false)
            .execute()
            .value

        return dtos.map { dto in
            Conversation(
                id: dto.id,
                userId: dto.userId,
                title: dto.title,
                starred: dto.starred,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
        }
    }

    func deleteConversation(id: String) async throws {
        // Messages cascade-deleted via FK constraint
        try await supabase.from("conversations")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Messages

    func upsertMessages(_ messages: [Message], forConversation conversationId: String) async throws {
        guard !messages.isEmpty else { return }

        let dtos = messages.map { msg in
            // Convert local file path to Supabase storage path so other devices can resolve it
            var cloudImageUrl = msg.imageUri
            if let localPath = msg.imageUri, localPath.hasPrefix("/") {
                let filename = URL(fileURLWithPath: localPath).lastPathComponent
                if let userId = currentUserId {
                    cloudImageUrl = "\(userId)/chat/\(filename)"
                }
            }

            return SupabaseMessageDTO(
                id: msg.id,
                conversationId: conversationId,
                role: msg.role.rawValue,
                content: msg.text,
                imageUrl: cloudImageUrl,
                createdAt: msg.createdAt,
                routerMetadata: msg.routerMetadata,
                contentType: msg.contentType?.rawValue
            )
        }

        try await supabase.from("messages")
            .upsert(dtos)
            .execute()
    }

    func fetchMessages(forConversation conversationId: String) async throws -> [Message] {
        let dtos: [SupabaseMessageDTO] = try await supabase.from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value

        return dtos.map { dto in
            Message(
                id: dto.id,
                conversationId: dto.conversationId,
                role: MessageRole(rawValue: dto.role) ?? .chloe,
                text: dto.content,
                imageUri: dto.imageUrl,
                createdAt: dto.createdAt,
                routerMetadata: dto.routerMetadata,
                contentType: dto.contentType.flatMap { MessageContentType(rawValue: $0) },
                options: nil  // Options stored in routerMetadata or re-parsed from text
            )
        }
    }

    // MARK: - Journal Entries

    func upsertJournalEntries(_ entries: [JournalEntry]) async throws {
        guard let userId = currentUserId, !entries.isEmpty else { return }

        let dtos = entries.map { entry in
            SupabaseJournalEntryDTO(
                id: entry.id,
                userId: userId,
                title: entry.title,
                content: entry.content,
                mood: entry.mood,
                createdAt: entry.createdAt
            )
        }

        try await supabase.from("journal_entries")
            .upsert(dtos)
            .execute()
    }

    func fetchJournalEntries() async throws -> [JournalEntry] {
        guard let userId = currentUserId else { return [] }

        let dtos: [SupabaseJournalEntryDTO] = try await supabase.from("journal_entries")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return dtos.map { dto in
            JournalEntry(
                id: dto.id,
                userId: dto.userId,
                title: dto.title,
                content: dto.content,
                mood: dto.mood,
                createdAt: dto.createdAt
            )
        }
    }

    // MARK: - Goals

    func upsertGoals(_ goals: [Goal]) async throws {
        guard let userId = currentUserId, !goals.isEmpty else { return }

        let dtos = goals.map { goal in
            SupabaseGoalDTO(
                id: goal.id,
                userId: userId,
                title: goal.title,
                description: goal.description,
                status: goal.status.rawValue,
                createdAt: goal.createdAt,
                completedAt: goal.completedAt,
                updatedAt: goal.updatedAt
            )
        }

        try await supabase.from("goals")
            .upsert(dtos)
            .execute()
    }

    func fetchGoals() async throws -> [Goal] {
        guard let userId = currentUserId else { return [] }

        let dtos: [SupabaseGoalDTO] = try await supabase.from("goals")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return dtos.map { dto in
            Goal(
                id: dto.id,
                userId: dto.userId,
                title: dto.title,
                description: dto.description,
                status: GoalStatus(rawValue: dto.status) ?? .active,
                createdAt: dto.createdAt,
                completedAt: dto.completedAt,
                updatedAt: dto.updatedAt
            )
        }
    }

    // MARK: - Affirmations

    func upsertAffirmations(_ affirmations: [Affirmation]) async throws {
        guard let userId = currentUserId, !affirmations.isEmpty else { return }

        let dtos = affirmations.map { affirmation in
            SupabaseAffirmationDTO(
                id: affirmation.id,
                userId: userId,
                text: affirmation.text,
                date: affirmation.date,
                isSaved: affirmation.isSaved,
                createdAt: affirmation.createdAt
            )
        }

        try await supabase.from("affirmations")
            .upsert(dtos)
            .execute()
    }

    func fetchAffirmations() async throws -> [Affirmation] {
        guard let userId = currentUserId else { return [] }

        let dtos: [SupabaseAffirmationDTO] = try await supabase.from("affirmations")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return dtos.map { dto in
            Affirmation(
                id: dto.id,
                userId: dto.userId,
                text: dto.text,
                date: dto.date,
                isSaved: dto.isSaved,
                createdAt: dto.createdAt
            )
        }
    }

    // MARK: - Vision Board Items

    func upsertVisionItems(_ items: [VisionItem]) async throws {
        guard let userId = currentUserId, !items.isEmpty else { return }

        let dtos = items.map { item in
            // Convert local file path to Supabase storage path so other devices can resolve it
            var cloudImageUrl = item.imageUri
            if let localPath = item.imageUri, localPath.hasPrefix("/") {
                let filename = URL(fileURLWithPath: localPath).lastPathComponent
                if let uid = currentUserId {
                    cloudImageUrl = "\(uid)/vision/\(filename)"
                }
            }

            return SupabaseVisionItemDTO(
                id: item.id,
                userId: userId,
                title: item.title,
                category: item.category.rawValue,
                imageUrl: cloudImageUrl,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            )
        }

        try await supabase.from("vision_board_items")
            .upsert(dtos)
            .execute()
    }

    func fetchVisionItems() async throws -> [VisionItem] {
        guard let userId = currentUserId else { return [] }

        let dtos: [SupabaseVisionItemDTO] = try await supabase.from("vision_board_items")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return dtos.map { dto in
            VisionItem(
                id: dto.id,
                userId: dto.userId,
                imageUri: dto.imageUrl,
                title: dto.title,
                category: VisionCategory(rawValue: dto.category) ?? .other,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
        }
    }

    // MARK: - User Facts

    func upsertUserFacts(_ facts: [UserFact]) async throws {
        guard let userId = currentUserId, !facts.isEmpty else { return }

        let dtos = facts.map { fact in
            SupabaseUserFactDTO(
                id: fact.id,
                userId: userId,
                fact: fact.fact,
                category: fact.category.rawValue,
                sourceType: "conversation",
                sourceId: fact.sourceMessageId,
                isActive: fact.isActive,
                createdAt: fact.createdAt,
                updatedAt: Date()
            )
        }

        try await supabase.from("user_facts")
            .upsert(dtos)
            .execute()
    }

    func fetchUserFacts() async throws -> [UserFact] {
        guard let userId = currentUserId else { return [] }

        let dtos: [SupabaseUserFactDTO] = try await supabase.from("user_facts")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return dtos.map { dto in
            UserFact(
                id: dto.id,
                userId: dto.userId,
                fact: dto.fact,
                category: FactCategory(rawValue: dto.category) ?? .goal,
                sourceMessageId: dto.sourceId,
                isActive: dto.isActive,
                createdAt: dto.createdAt
            )
        }
    }

    // MARK: - Delete Individual Items

    func deleteGoal(id: String) async throws {
        try await supabase.from("goals")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func deleteJournalEntry(id: String) async throws {
        try await supabase.from("journal_entries")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func deleteVisionItem(id: String) async throws {
        try await supabase.from("vision_board_items")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func deleteAffirmation(id: String) async throws {
        try await supabase.from("affirmations")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Storage (Images)

    private let storageBucket = "chloe-images"

    /// Upload profile image and return the storage path
    func uploadProfileImage(_ data: Data) async throws -> String {
        guard let userId = currentUserId else { throw StorageError.notAuthenticated }
        let path = "\(userId)/profile/profile_image.jpg"
        try await supabase.storage.from(storageBucket)
            .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))
        return path
    }

    /// Upload a chat image and return the storage path
    func uploadChatImage(_ data: Data, messageId: String) async throws -> String {
        guard let userId = currentUserId else { throw StorageError.notAuthenticated }
        let path = "\(userId)/chat/\(messageId).jpg"
        try await supabase.storage.from(storageBucket)
            .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))
        return path
    }

    /// Upload a vision board image and return the storage path
    func uploadVisionImage(_ data: Data, itemId: String) async throws -> String {
        guard let userId = currentUserId else { throw StorageError.notAuthenticated }
        let path = "\(userId)/vision/\(itemId).jpg"
        try await supabase.storage.from(storageBucket)
            .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))
        return path
    }

    /// Get a signed URL for a storage path (valid for 1 hour)
    func getSignedURL(path: String) async throws -> URL {
        try await supabase.storage.from(storageBucket)
            .createSignedURL(path: path, expiresIn: 3600)
    }

    /// Download image data from a storage path
    func downloadImage(path: String) async throws -> Data {
        let url = try await getSignedURL(path: path)
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    /// Delete an image from storage
    func deleteStorageImage(path: String) async throws {
        try await supabase.storage.from(storageBucket)
            .remove(paths: [path])
    }

    // MARK: - Delete All User Data

    /// Deletes the user's profile row — CASCADE handles all child tables.
    /// Also removes all images from storage bucket.
    func deleteAllUserData() async throws {
        guard let userId = currentUserId else { return }

        // Delete all storage files for this user
        do {
            let profileFiles = try await supabase.storage.from(storageBucket).list(path: "\(userId)/profile")
            let chatFiles = try await supabase.storage.from(storageBucket).list(path: "\(userId)/chat")
            let visionFiles = try await supabase.storage.from(storageBucket).list(path: "\(userId)/vision")

            var paths: [String] = []
            paths += profileFiles.map { "\(userId)/profile/\($0.name)" }
            paths += chatFiles.map { "\(userId)/chat/\($0.name)" }
            paths += visionFiles.map { "\(userId)/vision/\($0.name)" }

            if !paths.isEmpty {
                try await supabase.storage.from(storageBucket).remove(paths: paths)
            }
        } catch {
            // Storage cleanup failed — continue with DB deletion
        }

        // Delete profile — CASCADE handles conversations, messages,
        // user_facts, journal_entries, goals, affirmations, vision_board_items, user_state
        try await supabase.from("profiles")
            .delete()
            .eq("id", value: userId)
            .execute()
    }
}

enum StorageError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated — cannot access storage"
        }
    }
}
