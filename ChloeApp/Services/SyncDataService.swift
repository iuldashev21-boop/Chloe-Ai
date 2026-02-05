import Foundation
import UIKit
import Combine

/// Offline-first data service. Wraps local StorageService + remote SupabaseDataService.
/// All reads come from local (instant). All writes go to local first, then async push to Supabase.
/// On app launch, pulls from Supabase and merges (server wins for profile).
class SyncDataService {
    static let shared = SyncDataService()

    private let local = StorageService.shared
    private let remote = SupabaseDataService.shared
    private let network = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    /// Tracks whether any writes happened while offline
    private var hasPendingChanges = false

    /// Prevents concurrent syncFromCloud() executions (Bug 2 fix)
    private var isSyncing = false

    private init() {
        // When connectivity restores, push all local state to cloud
        network.didReconnect
            .sink { [weak self] in
                guard let self, self.hasPendingChanges else { return }
                self.hasPendingChanges = false
                Task { await self.pushAllToCloud() }
            }
            .store(in: &cancellables)
    }

    /// Push current local state to Supabase (idempotent — safe to call anytime)
    func pushAllToCloud() async {
        guard network.isConnected else { return }

        pushProfileToCloud()
        pushUserStateToCloud()

        let conversations = local.loadConversations()
        for convo in conversations {
            pushConversationToCloud(convo)
            let messages = local.loadMessages(forConversation: convo.id)
            if !messages.isEmpty {
                pushMessagesToCloud(messages, forConversation: convo.id)
            }
        }

        let journal = local.loadJournalEntries()
        if !journal.isEmpty { pushJournalEntriesToCloud(journal) }

        let goals = local.loadGoals()
        if !goals.isEmpty { pushGoalsToCloud(goals) }

        let affirmations = local.loadAffirmations()
        if !affirmations.isEmpty { pushAffirmationsToCloud(affirmations) }

        let visionItems = local.loadVisionItems()
        if !visionItems.isEmpty { pushVisionItemsToCloud(visionItems) }

        let facts = local.loadUserFacts()
        if !facts.isEmpty { pushUserFactsToCloud(facts) }
    }

    // MARK: - Cloud Sync (call on app launch)

    func syncFromCloud() async {
        // Prevent concurrent sync executions (Bug 2 fix)
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        guard network.isConnected else { return }

        // Sync profile (server wins if newer)
        do {
            if let remoteProfile = try await remote.fetchProfile() {
                let localProfile = local.loadProfile()
                if localProfile == nil || remoteProfile.updatedAt > (localProfile?.updatedAt ?? .distantPast) {
                    try local.saveProfile(remoteProfile)
                }
            }
        } catch {
            // Profile not found or network error — skip silently
        }

        // Sync conversations + messages (merge: union by ID, server wins for metadata)
        do {
            let remoteConversations = try await remote.fetchConversations()
            let localConversations = local.loadConversations()
            let localConvoMap = Dictionary(uniqueKeysWithValues: localConversations.map { ($0.id, $0) })

            var merged = localConversations
            for remoteConvo in remoteConversations {
                if let localConvo = localConvoMap[remoteConvo.id] {
                    // Server wins if newer
                    if remoteConvo.updatedAt > localConvo.updatedAt {
                        if let idx = merged.firstIndex(where: { $0.id == remoteConvo.id }) {
                            merged[idx] = remoteConvo
                        }
                    }
                } else {
                    // New conversation from cloud — add it
                    merged.append(remoteConvo)
                }
                // Merge messages for this conversation
                do {
                    let remoteMessages = try await remote.fetchMessages(forConversation: remoteConvo.id)
                    let localMessages = local.loadMessages(forConversation: remoteConvo.id)
                    let localMsgIds = Set(localMessages.map { $0.id })
                    var mergedMessages = localMessages
                    for msg in remoteMessages where !localMsgIds.contains(msg.id) {
                        mergedMessages.append(msg)
                    }
                    mergedMessages.sort { $0.createdAt < $1.createdAt }
                    if mergedMessages.count > localMessages.count {
                        try local.saveMessages(mergedMessages, forConversation: remoteConvo.id)
                    }
                } catch {
                    // Message sync failed for this conversation — skip
                }
            }
            try local.saveConversations(merged)
        } catch {
            // Conversation sync failed — skip silently
        }

        // Sync user_state (server wins if newer)
        do {
            if let remoteState = try await remote.fetchUserState() {
                let localUsage = local.loadDailyUsage()
                let localStreak = local.loadStreak()

                // Server wins if remote updatedAt is newer
                let localUpdated = max(
                    localUsage.date > remoteState.usageDate ? Date() : .distantPast,
                    localStreak.lastActiveDate > remoteState.lastActiveDate ? Date() : .distantPast
                )

                if remoteState.updatedAt > localUpdated {
                    // Apply remote state to local
                    try local.saveDailyUsage(DailyUsage(
                        date: remoteState.usageDate,
                        messageCount: remoteState.messageCount
                    ))
                    local.saveStreak(GlowUpStreak(
                        currentStreak: remoteState.currentStreak,
                        longestStreak: remoteState.longestStreak,
                        lastActiveDate: remoteState.lastActiveDate
                    ))
                    if let vibeRaw = remoteState.latestVibe,
                       let vibe = VibeScore(rawValue: vibeRaw) {
                        local.saveLatestVibe(vibe)
                    }
                    if let summary = remoteState.latestSummary {
                        local.saveLatestSummary(summary)
                    }
                    local.saveMessagesSinceAnalysis(remoteState.messagesSinceAnalysis)
                    local.replaceInsightEntries(remoteState.insightQueue)
                }
            }
        } catch {
            // User state not found or network error — skip silently
        }

        // Sync journal entries (merge by ID)
        do {
            let remoteEntries = try await remote.fetchJournalEntries()
            let localEntries = local.loadJournalEntries()
            let localIds = Set(localEntries.map { $0.id })
            var merged = localEntries
            for entry in remoteEntries where !localIds.contains(entry.id) {
                merged.append(entry)
            }
            if merged.count > localEntries.count {
                merged.sort { $0.createdAt > $1.createdAt }
                try local.saveJournalEntries(merged)
            }
        } catch {}

        // Sync goals (timestamp-based merge - server wins if newer)
        do {
            let remoteGoals = try await remote.fetchGoals()
            let localGoals = local.loadGoals()
            let localMap = Dictionary(uniqueKeysWithValues: localGoals.map { ($0.id, $0) })

            var merged = localGoals
            var hasChanges = false

            for remoteGoal in remoteGoals {
                if let localGoal = localMap[remoteGoal.id] {
                    // Server wins if newer
                    if remoteGoal.updatedAt > localGoal.updatedAt {
                        if let idx = merged.firstIndex(where: { $0.id == remoteGoal.id }) {
                            merged[idx] = remoteGoal
                            hasChanges = true
                        }
                    }
                } else {
                    // New goal from cloud
                    merged.append(remoteGoal)
                    hasChanges = true
                }
            }

            if hasChanges {
                try local.saveGoals(merged)
            }
        } catch {}

        // Sync affirmations (merge by ID)
        do {
            let remoteAffirmations = try await remote.fetchAffirmations()
            let localAffirmations = local.loadAffirmations()
            let localIds = Set(localAffirmations.map { $0.id })
            var merged = localAffirmations
            for affirmation in remoteAffirmations where !localIds.contains(affirmation.id) {
                merged.append(affirmation)
            }
            if merged.count > localAffirmations.count {
                merged.sort { $0.createdAt > $1.createdAt }
                try local.saveAffirmations(merged)
            }
        } catch {}

        // Sync vision board items (merge by ID + download images)
        do {
            let remoteItems = try await remote.fetchVisionItems()
            let localItems = local.loadVisionItems()
            let localIds = Set(localItems.map { $0.id })
            var merged = localItems
            var hasChanges = false

            for var item in remoteItems where !localIds.contains(item.id) {
                // Download image if it's a remote storage path (not a local file path)
                if let imageUrl = item.imageUri,
                   imageUrl.contains("/") && !imageUrl.hasPrefix("/") && !FileManager.default.fileExists(atPath: imageUrl) {
                    // It's a Supabase storage path, download it
                    if let data = try? await remote.downloadImage(path: imageUrl),
                       let localPath = local.saveVisionImage(data, itemId: item.id) {
                        item.imageUri = localPath
                    }
                }
                merged.append(item)
                hasChanges = true
            }

            if hasChanges {
                try local.saveVisionItems(merged)
            }
        } catch {}

        // Sync user facts (merge by ID)
        do {
            let remoteFacts = try await remote.fetchUserFacts()
            let localFacts = local.loadUserFacts()
            let localIds = Set(localFacts.map { $0.id })
            var merged = localFacts
            for fact in remoteFacts where !localIds.contains(fact.id) {
                merged.append(fact)
            }
            if merged.count > localFacts.count {
                try local.saveUserFacts(merged)
            }
        } catch {}
    }

    // MARK: - Async Supabase Push (fire-and-forget)

    private func pushUserStateToCloud() {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task {
            do {
                let usage = local.loadDailyUsage()
                let streak = local.loadStreak()
                let vibe = local.loadLatestVibe()
                let summary = local.loadLatestSummary()
                let msgsSince = local.loadMessagesSinceAnalysis()
                let insights = local.loadInsightEntries()

                try await remote.upsertUserState(
                    usage: usage,
                    streak: streak,
                    vibe: vibe,
                    summary: summary,
                    messagesSinceAnalysis: msgsSince,
                    insightQueue: insights
                )
            } catch {
                hasPendingChanges = true
            }
        }
    }

    private func pushProfileToCloud() {
        guard network.isConnected else { hasPendingChanges = true; return }
        guard let profile = local.loadProfile() else { return }
        Task {
            do {
                try await remote.upsertProfile(profile)
            } catch {
                hasPendingChanges = true
            }
        }
    }

    // MARK: - Profile

    func saveProfile(_ profile: Profile) throws {
        try local.saveProfile(profile)
        pushProfileToCloud()
    }

    func loadProfile() -> Profile? {
        return local.loadProfile()
    }

    /// Add new behavioral loops to profile with deduplication (case-insensitive)
    func addBehavioralLoops(_ newLoops: [String]) {
        guard !newLoops.isEmpty else { return }
        guard var profile = local.loadProfile() else { return }

        var existingLoops = profile.behavioralLoops ?? []
        let existingLowercased = Set(existingLoops.map { $0.lowercased() })

        for loop in newLoops {
            let loopLower = loop.lowercased()
            // Skip if exact match or substring of existing loop
            let isDuplicate = existingLowercased.contains(loopLower) ||
                existingLoops.contains { existing in
                    existing.lowercased().contains(loopLower) || loopLower.contains(existing.lowercased())
                }
            if !isDuplicate {
                existingLoops.append(loop)
            }
        }

        profile.behavioralLoops = existingLoops
        profile.updatedAt = Date()
        try? local.saveProfile(profile)
        pushProfileToCloud()
    }

    // MARK: - Chat Images

    func saveChatImage(_ image: UIImage) -> String? {
        let localPath = local.saveChatImage(image)
        // Async upload to Supabase Storage
        if let localPath, let data = image.jpegData(compressionQuality: 0.8) {
            let messageId = URL(fileURLWithPath: localPath).deletingPathExtension().lastPathComponent
            pushChatImageToCloud(data, messageId: messageId)
        }
        return localPath
    }

    private func pushChatImageToCloud(_ data: Data, messageId: String) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.uploadChatImage(data, messageId: messageId) }
    }

    // MARK: - Profile Image

    func saveProfileImage(_ imageData: Data) throws -> String {
        let localPath = try local.saveProfileImage(imageData)
        pushProfileImageToCloud(imageData)
        return localPath
    }

    func loadProfileImage() -> Data? {
        return local.loadProfileImage()
    }

    func deleteProfileImage() throws {
        try local.deleteProfileImage()
        guard network.isConnected else { return }
        if let userId = remote.currentUserId {
            let path = "\(userId)/profile/profile_image.jpg"
            Task { try? await remote.deleteStorageImage(path: path) }
        }
    }

    private func pushProfileImageToCloud(_ data: Data) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.uploadProfileImage(data) }
    }

    // MARK: - Conversations (+ cloud sync)

    func saveConversations(_ conversations: [Conversation]) throws {
        try local.saveConversations(conversations)
    }

    func loadConversations() -> [Conversation] {
        return local.loadConversations()
    }

    func saveConversation(_ conversation: Conversation) throws {
        try local.saveConversation(conversation)
        pushConversationToCloud(conversation)
    }

    func loadConversation(id: String) -> Conversation? {
        return local.loadConversation(id: id)
    }

    func renameConversation(id: String, newTitle: String) throws {
        try local.renameConversation(id: id, newTitle: newTitle)
        if let updated = local.loadConversation(id: id) {
            pushConversationToCloud(updated)
        }
    }

    func toggleConversationStar(id: String) throws {
        try local.toggleConversationStar(id: id)
        if let updated = local.loadConversation(id: id) {
            pushConversationToCloud(updated)
        }
    }

    /// Returns `false` if offline (deletion blocked to prevent orphaned cloud data).
    @discardableResult
    func deleteConversation(id: String) -> Bool {
        guard network.isConnected else { return false }
        local.deleteConversation(id: id)
        Task { try? await remote.deleteConversation(id: id) }
        return true
    }

    private func pushConversationToCloud(_ conversation: Conversation) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task {
            do {
                try await remote.upsertConversation(conversation)
            } catch {
                hasPendingChanges = true
            }
        }
    }

    // MARK: - Messages (+ cloud sync)

    func saveMessages(_ messages: [Message], forConversation conversationId: String) throws {
        try local.saveMessages(messages, forConversation: conversationId)
        pushMessagesToCloud(messages, forConversation: conversationId)
    }

    func loadMessages(forConversation conversationId: String) -> [Message] {
        return local.loadMessages(forConversation: conversationId)
    }

    private func pushMessagesToCloud(_ messages: [Message], forConversation conversationId: String) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.upsertMessages(messages, forConversation: conversationId) }
    }

    // MARK: - Journal (+ cloud sync)

    func saveJournalEntries(_ entries: [JournalEntry]) throws {
        try local.saveJournalEntries(entries)
        pushJournalEntriesToCloud(entries)
    }

    func loadJournalEntries() -> [JournalEntry] {
        return local.loadJournalEntries()
    }

    private func pushJournalEntriesToCloud(_ entries: [JournalEntry]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.upsertJournalEntries(entries) }
    }

    // MARK: - Goals (+ cloud sync)

    func saveGoals(_ goals: [Goal]) throws {
        try local.saveGoals(goals)
        pushGoalsToCloud(goals)
    }

    func loadGoals() -> [Goal] {
        return local.loadGoals()
    }

    private func pushGoalsToCloud(_ goals: [Goal]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.upsertGoals(goals) }
    }

    // MARK: - Affirmations (+ cloud sync)

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        try local.saveAffirmations(affirmations)
        pushAffirmationsToCloud(affirmations)
    }

    func loadAffirmations() -> [Affirmation] {
        return local.loadAffirmations()
    }

    private func pushAffirmationsToCloud(_ affirmations: [Affirmation]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.upsertAffirmations(affirmations) }
    }

    // MARK: - Vision Board (+ cloud sync)

    func saveVisionItems(_ items: [VisionItem]) throws {
        try local.saveVisionItems(items)
        pushVisionItemsToCloud(items)
        // Upload any local image files to Supabase Storage
        for item in items {
            if let path = item.imageUri, FileManager.default.fileExists(atPath: path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                pushVisionImageToCloud(data, itemId: item.id)
            }
        }
    }

    func loadVisionItems() -> [VisionItem] {
        return local.loadVisionItems()
    }

    private func pushVisionItemsToCloud(_ items: [VisionItem]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.upsertVisionItems(items) }
    }

    private func pushVisionImageToCloud(_ data: Data, itemId: String) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.uploadVisionImage(data, itemId: itemId) }
    }

    // MARK: - User Facts (+ cloud sync)

    func saveUserFacts(_ facts: [UserFact]) throws {
        try local.saveUserFacts(facts)
        pushUserFactsToCloud(facts)
    }

    func loadUserFacts() -> [UserFact] {
        return local.loadUserFacts()
    }

    private func pushUserFactsToCloud(_ facts: [UserFact]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { try? await remote.upsertUserFacts(facts) }
    }

    // MARK: - Latest Vibe (+ cloud sync)

    func saveLatestVibe(_ vibe: VibeScore) {
        local.saveLatestVibe(vibe)
        pushUserStateToCloud()
    }

    func loadLatestVibe() -> VibeScore? {
        return local.loadLatestVibe()
    }

    // MARK: - Daily Usage (+ cloud sync)

    func saveDailyUsage(_ usage: DailyUsage) throws {
        try local.saveDailyUsage(usage)
        pushUserStateToCloud()
    }

    func loadDailyUsage() -> DailyUsage {
        return local.loadDailyUsage()
    }

    // MARK: - Messages Since Analysis (+ cloud sync)

    func saveMessagesSinceAnalysis(_ count: Int) {
        local.saveMessagesSinceAnalysis(count)
        pushUserStateToCloud()
    }

    func loadMessagesSinceAnalysis() -> Int {
        return local.loadMessagesSinceAnalysis()
    }

    // MARK: - Streak (+ cloud sync)

    func saveStreak(_ streak: GlowUpStreak) {
        local.saveStreak(streak)
        pushUserStateToCloud()
    }

    func loadStreak() -> GlowUpStreak {
        return local.loadStreak()
    }

    // MARK: - Latest Summary (+ cloud sync)

    func saveLatestSummary(_ summary: String) {
        local.saveLatestSummary(summary)
        pushUserStateToCloud()
    }

    func loadLatestSummary() -> String? {
        return local.loadLatestSummary()
    }

    // MARK: - Insight Queue (+ cloud sync)

    func pushInsight(_ insight: String) {
        local.pushInsight(insight)
        pushUserStateToCloud()
    }

    func popInsight() -> String? {
        let result = local.popInsight()
        if result != nil {
            pushUserStateToCloud()
        }
        return result
    }

    // MARK: - Notification Rate Limiting (local-only)

    func incrementGenericNotificationCount() {
        local.incrementGenericNotificationCount()
    }

    func getGenericNotificationCountThisWeek() -> Int {
        return local.getGenericNotificationCountThisWeek()
    }

    func canSendGenericNotification() -> Bool {
        return local.canSendGenericNotification()
    }

    // MARK: - Notification Permission Priming (local-only)

    func setNotificationPrimingShown() {
        local.setNotificationPrimingShown()
    }

    func hasShownNotificationPriming() -> Bool {
        return local.hasShownNotificationPriming()
    }

    func setNotificationDeniedAfterPriming() {
        local.setNotificationDeniedAfterPriming()
    }

    func wasNotificationDeniedAfterPriming() -> Bool {
        return local.wasNotificationDeniedAfterPriming()
    }

    // MARK: - Clear All

    func clearAll() {
        local.clearAll()
        hasPendingChanges = false
        // Also delete all data from Supabase (async, best-effort)
        guard network.isConnected else { return }
        Task { try? await remote.deleteAllUserData() }
    }
}
