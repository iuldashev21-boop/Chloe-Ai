import Foundation
import UIKit
import Combine

// MARK: - App Event Bus (replaces custom Notification.Name broadcasts)

/// Lightweight Combine-based event bus for app-wide events.
/// Replaces NotificationCenter custom notifications with type-safe publishers.
enum AppEvents {
    /// Fired when onboarding completes (from OnboardingViewModel, dev skip flows, etc.)
    static let onboardingDidComplete = PassthroughSubject<Void, Never>()

    /// Fired when SyncDataService finishes pulling profile/data from cloud
    static let profileDidSyncFromCloud = PassthroughSubject<Void, Never>()

    /// Fired when a deep-link auth callback is processed by ChloeApp
    static let authDeepLinkReceived = PassthroughSubject<Void, Never>()
}

// MARK: - Sync Status

/// Represents the current state of cloud synchronization.
enum SyncStatus: Equatable {
    case idle           // Nothing to sync
    case syncing        // Currently syncing
    case pending        // Has unsynced changes, waiting to retry
    case error(String)  // Last sync failed with reason
}

/// Thread-safe actor for sync state management (Bug 2 fix)
private actor SyncLock {
    private var isSyncing = false

    func tryStartSync() -> Bool {
        if isSyncing { return false }
        isSyncing = true
        return true
    }

    func endSync() {
        isSyncing = false
    }
}

/// Offline-first data service. Wraps local StorageService + remote SupabaseDataService.
/// All reads come from local (instant). All writes go to local first, then async push to Supabase.
/// On app launch, pulls from Supabase and merges (server wins for profile).
class SyncDataService: ObservableObject {
    static let shared = SyncDataService()

    private let local = StorageService.shared
    private let remote = SupabaseDataService.shared
    private let network = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    /// Published sync status for UI observation
    @Published var syncStatus: SyncStatus = .idle

    /// Tracks whether any writes happened while offline (thread-safe via lock)
    private let _pendingLock = NSLock()
    private var _hasPendingChanges = false
    private var hasPendingChanges: Bool {
        get { _pendingLock.lock(); defer { _pendingLock.unlock() }; return _hasPendingChanges }
        set {
            _pendingLock.lock()
            _hasPendingChanges = newValue
            _pendingLock.unlock()
            if newValue {
                scheduleRetry()
            }
        }
    }

    /// In-flight cloud sync tasks — cancelled on clearAll() to prevent stale writes
    private var inflightTasks: [Task<Void, Never>] = []
    private let _taskLock = NSLock()

    /// Retry state
    private var retryTask: Task<Void, Never>?
    private var retryCount = 0
    private let maxRetries = 3

    /// Track a fire-and-forget cloud task so it can be cancelled on sign-out
    private func trackTask(_ task: Task<Void, Never>) {
        _taskLock.lock()
        inflightTasks.removeAll { $0.isCancelled }
        inflightTasks.append(task)
        _taskLock.unlock()
    }

    /// Cancel all in-flight cloud tasks (called on sign-out)
    private func cancelAllInflightTasks() {
        _taskLock.lock()
        for task in inflightTasks { task.cancel() }
        inflightTasks.removeAll()
        _taskLock.unlock()
    }

    /// Thread-safe sync lock using actor (Bug 2 fix)
    private let syncLock = SyncLock()

    private init() {
        // When connectivity restores, push all local state to cloud
        network.didReconnect
            .sink { [weak self] in
                guard let self, self.hasPendingChanges else { return }
                self.retryCount = 0 // Reset retry count on reconnect
                Task { await self.retryPendingSync() }
            }
            .store(in: &cancellables)
    }

    // MARK: - Retry Mechanism

    /// Schedule an automatic retry after 30 seconds. Cancels any existing scheduled retry.
    private func scheduleRetry() {
        retryTask?.cancel()
        guard retryCount < maxRetries else {
            DispatchQueue.main.async { [weak self] in
                self?.syncStatus = .pending
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            if self?.syncStatus != .syncing {
                self?.syncStatus = .pending
            }
        }
        retryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            guard !Task.isCancelled else { return }
            await self?.retryPendingSync()
        }
    }

    /// Retry pushing pending changes to cloud. Can be called manually or automatically.
    func retryPendingSync() async {
        guard hasPendingChanges else {
            await MainActor.run { syncStatus = .idle }
            return
        }
        guard network.isConnected else {
            await MainActor.run { syncStatus = .pending }
            return
        }

        retryCount += 1
        await MainActor.run { syncStatus = .syncing }

        await pushAllToCloud()

        // Check if pushAllToCloud encountered errors (hasPendingChanges would be re-set)
        if hasPendingChanges {
            if retryCount >= maxRetries {
                await MainActor.run { syncStatus = .pending }
            } else {
                scheduleRetry()
            }
        } else {
            retryCount = 0
            await MainActor.run { syncStatus = .idle }
        }
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
        // Thread-safe check to prevent concurrent sync executions (Bug 2 fix)
        guard await syncLock.tryStartSync() else { return }
        defer { Task { await syncLock.endSync() } }

        guard network.isConnected else { return }

        await MainActor.run { syncStatus = .syncing }

        // Sync profile (server wins if newer)
        do {
            if var remoteProfile = try await remote.fetchProfile() {
                let localProfile = local.loadProfile()
                if localProfile == nil || remoteProfile.updatedAt > (localProfile?.updatedAt ?? .distantPast) {
                    // Re-download profile image if local file is missing (e.g. after reinstall)
                    if let imageUri = remoteProfile.profileImageUri,
                       !FileManager.default.fileExists(atPath: imageUri),
                       let userId = remote.currentUserId {
                        let storagePath = "\(userId)/profile/profile_image.jpg"
                        if let data = try? await remote.downloadImage(path: storagePath),
                           let localPath = try? local.saveProfileImage(data) {
                            remoteProfile.profileImageUri = localPath
                        }
                    }
                    try local.saveProfile(remoteProfile)
                }
            }
        } catch {
            #if DEBUG
            print("[SyncDataService] Profile sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.profile")
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

                    // Re-download missing chat images (handles reinstall / new device)
                    var imageUpdated = false
                    for i in mergedMessages.indices {
                        guard let imageUri = mergedMessages[i].imageUri, !imageUri.isEmpty else { continue }

                        // Determine the storage path and local filename
                        let storagePath: String
                        let localFilename: String
                        if imageUri.hasPrefix("/") {
                            // Old-style local path stored in cloud — reconstruct storage path
                            guard !FileManager.default.fileExists(atPath: imageUri) else { continue }
                            localFilename = URL(fileURLWithPath: imageUri).lastPathComponent
                            guard let userId = remote.currentUserId else { continue }
                            storagePath = "\(userId)/chat/\(localFilename)"
                        } else {
                            // Already a storage path (e.g. "userId/chat/file.jpg")
                            localFilename = URL(string: imageUri)?.lastPathComponent ?? imageUri.components(separatedBy: "/").last ?? imageUri
                            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let localPath = dir.appendingPathComponent(localFilename).path
                            guard !FileManager.default.fileExists(atPath: localPath) else {
                                // File exists locally — just fix the path reference
                                if mergedMessages[i].imageUri != localPath {
                                    mergedMessages[i].imageUri = localPath
                                    imageUpdated = true
                                }
                                continue
                            }
                            storagePath = imageUri
                        }

                        // Download from Supabase Storage
                        if let data = try? await remote.downloadImage(path: storagePath),
                           let localPath = local.saveChatImageData(data, filename: localFilename) {
                            mergedMessages[i].imageUri = localPath
                            imageUpdated = true
                        }
                    }
                    if imageUpdated {
                        try local.saveMessages(mergedMessages, forConversation: remoteConvo.id)
                    }
                } catch {
                    #if DEBUG
                    print("[SyncDataService] Message sync failed for conversation \(remoteConvo.id): \(error.localizedDescription)")
                    #endif
                    trackSignal("sync.error.messages")
                }
            }
            try local.saveConversations(merged)
        } catch {
            #if DEBUG
            print("[SyncDataService] Conversation sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.conversations")
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
            #if DEBUG
            print("[SyncDataService] User state sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.userState")
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
        } catch {
            #if DEBUG
            print("[SyncDataService] Journal sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.journal")
        }

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
        } catch {
            #if DEBUG
            print("[SyncDataService] Goals sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.goals")
        }

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
        } catch {
            #if DEBUG
            print("[SyncDataService] Affirmations sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.affirmations")
        }

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
        } catch {
            #if DEBUG
            print("[SyncDataService] Vision board sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.visionBoard")
        }

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
        } catch {
            #if DEBUG
            print("[SyncDataService] User facts sync failed: \(error.localizedDescription)")
            #endif
            trackSignal("sync.error.userFacts")
        }

        // Notify that profile sync completed (for onboarding state refresh)
        await MainActor.run {
            AppEvents.profileDidSyncFromCloud.send()
            if !hasPendingChanges {
                syncStatus = .idle
            }
        }
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
        Task { [weak self] in
            await MainActor.run { self?.syncStatus = .syncing }
            do {
                try await self?.remote.upsertProfile(profile)
                await MainActor.run {
                    if self?.hasPendingChanges != true { self?.syncStatus = .idle }
                }
            } catch {
                self?.hasPendingChanges = true
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

        // Cap at 20 entries — drop oldest to prevent unbounded growth
        let maxLoops = 20
        if existingLoops.count > maxLoops {
            existingLoops = Array(existingLoops.suffix(maxLoops))
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
        Task {
            do {
                _ = try await remote.uploadChatImage(data, messageId: messageId)
            } catch {
                #if DEBUG
                print("[SyncDataService] Chat image upload failed for \(messageId): \(error.localizedDescription)")
                #endif
                hasPendingChanges = true
            }
        }
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
            Task { [remote] in
                do {
                    try await remote.deleteStorageImage(path: path)
                } catch {
                    #if DEBUG
                    print("[SyncDataService] Profile image cloud delete failed: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }

    private func pushProfileImageToCloud(_ data: Data) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task {
            do {
                _ = try await remote.uploadProfileImage(data)
            } catch {
                #if DEBUG
                print("[SyncDataService] Profile image upload failed: \(error.localizedDescription)")
                #endif
                hasPendingChanges = true
            }
        }
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
        Task { [remote] in
            do {
                try await remote.deleteConversation(id: id)
            } catch {
                #if DEBUG
                print("[SyncDataService] Cloud delete failed for conversation \(id): \(error.localizedDescription)")
                #endif
            }
        }
        return true
    }

    private func pushConversationToCloud(_ conversation: Conversation) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { [weak self] in
            await MainActor.run { self?.syncStatus = .syncing }
            do {
                try await self?.remote.upsertConversation(conversation)
                await MainActor.run {
                    if self?.hasPendingChanges != true { self?.syncStatus = .idle }
                }
            } catch {
                self?.hasPendingChanges = true
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

    func loadMessages(forConversation conversationId: String, limit: Int) -> [Message] {
        return local.loadMessages(forConversation: conversationId, limit: limit)
    }

    func messageCount(forConversation conversationId: String) -> Int {
        return local.messageCount(forConversation: conversationId)
    }

    private func pushMessagesToCloud(_ messages: [Message], forConversation conversationId: String) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { [weak self] in
            await MainActor.run { self?.syncStatus = .syncing }
            do {
                try await self?.remote.upsertMessages(messages, forConversation: conversationId)
                await MainActor.run {
                    if self?.hasPendingChanges != true { self?.syncStatus = .idle }
                }
            } catch {
                self?.hasPendingChanges = true
            }
        }
    }

    // MARK: - Journal (+ cloud sync)

    func saveJournalEntries(_ entries: [JournalEntry]) throws {
        try local.saveJournalEntries(entries)
        pushJournalEntriesToCloud(entries)
    }

    func loadJournalEntries() -> [JournalEntry] {
        return local.loadJournalEntries()
    }

    /// Delete a journal entry locally and from cloud. Returns false if offline.
    @discardableResult
    func deleteJournalEntry(id: String) -> Bool {
        guard network.isConnected else { return false }
        var entries = local.loadJournalEntries()
        entries.removeAll { $0.id == id }
        try? local.saveJournalEntries(entries)
        let task = Task { [remote] in
            do {
                try await remote.deleteJournalEntry(id: id)
            } catch {
                #if DEBUG
                print("[SyncDataService] Cloud delete failed for journal entry \(id): \(error.localizedDescription)")
                #endif
            }
        }
        trackTask(task)
        return true
    }

    private func pushJournalEntriesToCloud(_ entries: [JournalEntry]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { [weak self] in
            await MainActor.run { self?.syncStatus = .syncing }
            do {
                try await self?.remote.upsertJournalEntries(entries)
                await MainActor.run {
                    if self?.hasPendingChanges != true { self?.syncStatus = .idle }
                }
            } catch {
                self?.hasPendingChanges = true
            }
        }
    }

    // MARK: - Goals (+ cloud sync)

    func saveGoals(_ goals: [Goal]) throws {
        try local.saveGoals(goals)
        pushGoalsToCloud(goals)
    }

    func loadGoals() -> [Goal] {
        return local.loadGoals()
    }

    /// Delete a goal locally and from cloud. Returns false if offline.
    @discardableResult
    func deleteGoal(id: String) -> Bool {
        guard network.isConnected else { return false }
        var goals = local.loadGoals()
        goals.removeAll { $0.id == id }
        try? local.saveGoals(goals)
        let task = Task { [remote] in
            do {
                try await remote.deleteGoal(id: id)
            } catch {
                #if DEBUG
                print("[SyncDataService] Cloud delete failed for goal \(id): \(error.localizedDescription)")
                #endif
            }
        }
        trackTask(task)
        return true
    }

    private func pushGoalsToCloud(_ goals: [Goal]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { [weak self] in
            await MainActor.run { self?.syncStatus = .syncing }
            do {
                try await self?.remote.upsertGoals(goals)
                await MainActor.run {
                    if self?.hasPendingChanges != true { self?.syncStatus = .idle }
                }
            } catch {
                self?.hasPendingChanges = true
            }
        }
    }

    // MARK: - Affirmations (+ cloud sync)

    func saveAffirmations(_ affirmations: [Affirmation]) throws {
        try local.saveAffirmations(affirmations)
        pushAffirmationsToCloud(affirmations)
    }

    func loadAffirmations() -> [Affirmation] {
        return local.loadAffirmations()
    }

    /// Delete an affirmation locally and from cloud. Returns false if offline.
    @discardableResult
    func deleteAffirmation(id: String) -> Bool {
        guard network.isConnected else { return false }
        var affirmations = local.loadAffirmations()
        affirmations.removeAll { $0.id == id }
        try? local.saveAffirmations(affirmations)
        let task = Task { [remote] in
            do {
                try await remote.deleteAffirmation(id: id)
            } catch {
                #if DEBUG
                print("[SyncDataService] Cloud delete failed for affirmation \(id): \(error.localizedDescription)")
                #endif
            }
        }
        trackTask(task)
        return true
    }

    private func pushAffirmationsToCloud(_ affirmations: [Affirmation]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { [weak self] in
            do { try await self?.remote.upsertAffirmations(affirmations) }
            catch { self?.hasPendingChanges = true }
        }
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

    /// Delete a vision item locally and from cloud (including storage image). Returns false if offline.
    @discardableResult
    func deleteVisionItem(id: String) -> Bool {
        guard network.isConnected else { return false }
        var items = local.loadVisionItems()
        items.removeAll { $0.id == id }
        try? local.saveVisionItems(items)
        let task = Task { [remote] in
            do {
                try await remote.deleteVisionItem(id: id)
            } catch {
                #if DEBUG
                print("[SyncDataService] Cloud delete failed for vision item \(id): \(error.localizedDescription)")
                #endif
            }
            if let userId = remote.currentUserId {
                let path = "\(userId)/vision/\(id).jpg"
                do {
                    try await remote.deleteStorageImage(path: path)
                } catch {
                    #if DEBUG
                    print("[SyncDataService] Vision image delete failed for \(id): \(error.localizedDescription)")
                    #endif
                }
            }
        }
        trackTask(task)
        return true
    }

    private func pushVisionItemsToCloud(_ items: [VisionItem]) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task { [weak self] in
            do { try await self?.remote.upsertVisionItems(items) }
            catch { self?.hasPendingChanges = true }
        }
    }

    private func pushVisionImageToCloud(_ data: Data, itemId: String) {
        guard network.isConnected else { hasPendingChanges = true; return }
        Task {
            do {
                _ = try await remote.uploadVisionImage(data, itemId: itemId)
            } catch {
                #if DEBUG
                print("[SyncDataService] Vision image upload failed for \(itemId): \(error.localizedDescription)")
                #endif
                hasPendingChanges = true
            }
        }
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
        Task { [weak self] in
            do { try await self?.remote.upsertUserFacts(facts) }
            catch { self?.hasPendingChanges = true }
        }
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

    /// Clears local data only (for sign out). Cloud data is preserved.
    func clearAll() {
        cancelAllInflightTasks()
        retryTask?.cancel()
        retryTask = nil
        retryCount = 0
        local.clearAll()
        _pendingLock.lock()
        _hasPendingChanges = false
        _pendingLock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.syncStatus = .idle
        }
        // Cloud data is intentionally NOT deleted on sign out.
        // User's data stays in Supabase so they can sign back in and restore it.
    }

    /// Deletes ALL user data - local AND cloud. Use only for explicit "Delete Account" action.
    /// Throws if cloud deletion fails so the caller can inform the user.
    func deleteAccount() async throws {
        cancelAllInflightTasks()
        retryTask?.cancel()
        retryTask = nil
        retryCount = 0
        local.clearAll()
        _pendingLock.lock()
        _hasPendingChanges = false
        _pendingLock.unlock()
        await MainActor.run { syncStatus = .idle }
        // Delete cloud data only on explicit account deletion
        guard network.isConnected else { return }
        try await remote.deleteAllUserData()
    }
}

// MARK: - Protocol Conformance

extension SyncDataService: SyncDataServiceProtocol {}
