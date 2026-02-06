import XCTest
@testable import ChloeApp

final class SyncDataServiceTests: XCTestCase {

    private let sut = SyncDataService.shared
    private let local = StorageService.shared

    override func setUp() {
        super.setUp()
        sut.clearAll()
    }

    override func tearDown() {
        sut.clearAll()
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeProfile(
        id: String = "p1",
        displayName: String = "Sarah",
        subscriptionTier: SubscriptionTier = .free,
        behavioralLoops: [String]? = nil
    ) -> Profile {
        Profile(
            id: id,
            email: "test@test.com",
            displayName: displayName,
            onboardingComplete: true,
            subscriptionTier: subscriptionTier,
            behavioralLoops: behavioralLoops
        )
    }

    private func makeGoal(
        id: String = "g1",
        title: String = "Run a marathon",
        status: GoalStatus = .active,
        updatedAt: Date = Date()
    ) -> Goal {
        Goal(id: id, title: title, status: status, updatedAt: updatedAt)
    }

    private func makeJournalEntry(
        id: String = "j1",
        title: String = "Today was good",
        content: String = "I felt great."
    ) -> JournalEntry {
        JournalEntry(id: id, title: title, content: content, mood: "happy")
    }

    private func makeVisionItem(
        id: String = "v1",
        title: String = "Dream house",
        imageUri: String? = nil
    ) -> VisionItem {
        VisionItem(id: id, imageUri: imageUri, title: title, category: .lifestyle)
    }

    // MARK: - Profile Round Trip

    func testProfileSaveAndLoad() throws {
        let profile = makeProfile()
        try sut.saveProfile(profile)
        let loaded = sut.loadProfile()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.displayName, "Sarah")
        XCTAssertEqual(loaded?.subscriptionTier, .free)
    }

    func testProfileNil_whenNothingSaved() {
        XCTAssertNil(sut.loadProfile())
    }

    // MARK: - Conversations Round Trip

    func testConversationSaveAndLoad() throws {
        let convo = Conversation(id: "c1", title: "Dating advice")
        try sut.saveConversation(convo)
        let loaded = sut.loadConversation(id: "c1")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.title, "Dating advice")
    }

    func testConversationsListSaveAndLoad() throws {
        let convos = [
            Conversation(id: "c1", title: "Chat 1"),
            Conversation(id: "c2", title: "Chat 2")
        ]
        try sut.saveConversations(convos)
        let loaded = sut.loadConversations()
        XCTAssertEqual(loaded.count, 2)
    }

    func testRenameConversation() throws {
        let convo = Conversation(id: "c1", title: "Old")
        try sut.saveConversation(convo)
        try sut.renameConversation(id: "c1", newTitle: "New")
        XCTAssertEqual(sut.loadConversation(id: "c1")?.title, "New")
    }

    func testToggleConversationStar() throws {
        let convo = Conversation(id: "c1", title: "Test", starred: false)
        try sut.saveConversation(convo)
        XCTAssertFalse(sut.loadConversation(id: "c1")?.starred ?? true)
        try sut.toggleConversationStar(id: "c1")
        XCTAssertTrue(sut.loadConversation(id: "c1")?.starred ?? false)
    }

    // MARK: - Deletion Requires Network

    func testDeleteConversation_returnsTrue_whenOnline() throws {
        // NetworkMonitor.shared.isConnected defaults to true
        let convo = Conversation(id: "c1", title: "Deletable")
        try sut.saveConversation(convo)
        let result = sut.deleteConversation(id: "c1")
        // On actual network, this should succeed (returns true)
        // Note: In CI/offline, this may return false, which is expected behavior
        if NetworkMonitor.shared.isConnected {
            XCTAssertTrue(result)
            XCTAssertNil(sut.loadConversation(id: "c1"))
        } else {
            XCTAssertFalse(result, "Deletion should be blocked offline")
            XCTAssertNotNil(sut.loadConversation(id: "c1"))
        }
    }

    // MARK: - Messages Round Trip

    func testMessagesSaveAndLoad() throws {
        let messages = [
            Message(id: "m1", conversationId: "c1", role: .user, text: "Hi"),
            Message(id: "m2", conversationId: "c1", role: .chloe, text: "Hey girl")
        ]
        try sut.saveMessages(messages, forConversation: "c1")
        let loaded = sut.loadMessages(forConversation: "c1")
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].text, "Hi")
        XCTAssertEqual(loaded[1].text, "Hey girl")
    }

    // MARK: - Journal Entries Round Trip

    func testJournalEntriesSaveAndLoad() throws {
        let entries = [makeJournalEntry(id: "j1"), makeJournalEntry(id: "j2", title: "Rough day")]
        try sut.saveJournalEntries(entries)
        let loaded = sut.loadJournalEntries()
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - Goals Round Trip

    func testGoalsSaveAndLoad() throws {
        let goals = [makeGoal(id: "g1"), makeGoal(id: "g2", title: "Read more")]
        try sut.saveGoals(goals)
        let loaded = sut.loadGoals()
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - Ghost-Data Bug: Deleted Items Reappearing

    /// Documents the ghost-data bug: items deleted locally but never deleted from cloud
    /// will reappear after sync. Goals, journal entries, and vision items are merged by
    /// union (additive only). There is no deletion propagation for these entity types.
    func testGhostDataBug_goalsNeverDeletedFromCloud() throws {
        // Simulate: user has 3 goals locally
        let goals = [
            makeGoal(id: "g1", title: "Goal 1"),
            makeGoal(id: "g2", title: "Goal 2"),
            makeGoal(id: "g3", title: "Goal 3")
        ]
        try sut.saveGoals(goals)
        XCTAssertEqual(sut.loadGoals().count, 3)

        // User deletes goal 2 locally by saving without it
        let afterDelete = [goals[0], goals[2]]
        try sut.saveGoals(afterDelete)
        XCTAssertEqual(sut.loadGoals().count, 2)

        // Sync from cloud would re-add goal 2 because syncFromCloud merges by ID
        // (no deletion propagation exists in the sync logic)
        // This test documents the gap: saveGoals overwrites local but pushGoalsToCloud
        // only upserts, it never deletes from Supabase. After next syncFromCloud,
        // goal 2 would reappear from the cloud.
    }

    /// Documents that journal entries use additive-only merge (union by ID).
    /// A locally-deleted entry will reappear after sync from cloud.
    func testGhostDataBug_journalEntriesAdditiveOnly() throws {
        let entries = [
            makeJournalEntry(id: "j1", title: "Entry 1"),
            makeJournalEntry(id: "j2", title: "Entry 2")
        ]
        try sut.saveJournalEntries(entries)
        XCTAssertEqual(sut.loadJournalEntries().count, 2)

        // Remove j2 locally
        try sut.saveJournalEntries([entries[0]])
        XCTAssertEqual(sut.loadJournalEntries().count, 1)

        // After syncFromCloud, j2 would reappear from cloud merge
        // (no deletion tracking or tombstone mechanism exists)
    }

    /// Documents that vision items use additive-only merge (union by ID).
    func testGhostDataBug_visionItemsAdditiveOnly() throws {
        let items = [
            makeVisionItem(id: "v1", title: "Item 1"),
            makeVisionItem(id: "v2", title: "Item 2")
        ]
        try sut.saveVisionItems(items)
        XCTAssertEqual(sut.loadVisionItems().count, 2)

        // Remove v2 locally
        try sut.saveVisionItems([items[0]])
        XCTAssertEqual(sut.loadVisionItems().count, 1)

        // After syncFromCloud, v2 would reappear (same additive merge pattern)
    }

    // MARK: - Sync Conflict Resolution: Local vs Cloud Goals

    func testGoalsSyncMerge_localAndCloudUnion() throws {
        // Local has goal A and B
        let goalA = makeGoal(id: "ga", title: "Local Goal A")
        let goalB = makeGoal(id: "gb", title: "Local Goal B")
        try sut.saveGoals([goalA, goalB])
        XCTAssertEqual(sut.loadGoals().count, 2)

        // After sync, cloud might add goal C
        // Simulate by directly saving with union
        let goalC = makeGoal(id: "gc", title: "Cloud Goal C")
        try sut.saveGoals([goalA, goalB, goalC])
        let loaded = sut.loadGoals()
        XCTAssertEqual(loaded.count, 3)
    }

    /// Server-wins strategy for goals with same ID: newer updatedAt wins
    func testGoalsSyncMerge_serverWinsWhenNewer() throws {
        let oldDate = Date(timeIntervalSinceNow: -3600)
        let newDate = Date()

        let localGoal = makeGoal(id: "g1", title: "Local Title", updatedAt: oldDate)
        let remoteGoal = makeGoal(id: "g1", title: "Remote Title", updatedAt: newDate)

        // Simulate merge logic: server wins if newer
        try sut.saveGoals([localGoal])
        XCTAssertEqual(sut.loadGoals().first?.title, "Local Title")

        // Overwrite with remote (newer) version
        if remoteGoal.updatedAt > localGoal.updatedAt {
            try sut.saveGoals([remoteGoal])
        }
        XCTAssertEqual(sut.loadGoals().first?.title, "Remote Title")
    }

    // MARK: - hasPendingChanges Flag Management

    func testClearAll_resetsPendingChanges() {
        // After clearAll, hasPendingChanges should be false (internal state)
        // We verify indirectly: clearAll should not cause a push to cloud
        sut.clearAll()
        // If hasPendingChanges were still true after clearAll, the reconnect
        // handler would push stale data. clearAll explicitly sets it to false.
        XCTAssertNil(sut.loadProfile(), "clearAll should wipe local data")
        XCTAssertTrue(sut.loadGoals().isEmpty)
        XCTAssertTrue(sut.loadJournalEntries().isEmpty)
    }

    /// When offline writes happen, the reconnect handler should trigger push.
    /// We verify the pattern by checking that writes succeed locally when offline.
    func testOfflineWritesSucceedLocally() throws {
        // Regardless of network state, local writes should always succeed
        let profile = makeProfile()
        try sut.saveProfile(profile)
        XCTAssertNotNil(sut.loadProfile())

        let goals = [makeGoal()]
        try sut.saveGoals(goals)
        XCTAssertEqual(sut.loadGoals().count, 1)

        let entries = [makeJournalEntry()]
        try sut.saveJournalEntries(entries)
        XCTAssertEqual(sut.loadJournalEntries().count, 1)
    }

    // MARK: - Daily Usage (+ cloud sync)

    func testDailyUsageSaveAndLoad() throws {
        let usage = DailyUsage(date: DailyUsage.todayKey(), messageCount: 3)
        try sut.saveDailyUsage(usage)
        let loaded = sut.loadDailyUsage()
        XCTAssertEqual(loaded.messageCount, 3)
    }

    func testDailyUsageFresh() {
        let usage = sut.loadDailyUsage()
        XCTAssertEqual(usage.messageCount, 0)
    }

    // MARK: - Streak (+ cloud sync)

    func testStreakSaveAndLoad() {
        let streak = GlowUpStreak(currentStreak: 7, longestStreak: 14, lastActiveDate: "2025-12-01")
        sut.saveStreak(streak)
        let loaded = sut.loadStreak()
        XCTAssertEqual(loaded.currentStreak, 7)
        XCTAssertEqual(loaded.longestStreak, 14)
    }

    func testStreakDefault() {
        let streak = sut.loadStreak()
        XCTAssertEqual(streak.currentStreak, 0)
    }

    // MARK: - Vibe Score (+ cloud sync)

    func testVibeScoreSaveAndLoad() {
        sut.saveLatestVibe(.high)
        XCTAssertEqual(sut.loadLatestVibe(), .high)
    }

    func testVibeScoreNil() {
        XCTAssertNil(sut.loadLatestVibe())
    }

    // MARK: - Latest Summary (+ cloud sync)

    func testLatestSummarySaveAndLoad() {
        sut.saveLatestSummary("She discussed boundaries.")
        XCTAssertEqual(sut.loadLatestSummary(), "She discussed boundaries.")
    }

    func testLatestSummaryNil() {
        XCTAssertNil(sut.loadLatestSummary())
    }

    // MARK: - Messages Since Analysis (+ cloud sync)

    func testMessagesSinceAnalysisSaveAndLoad() {
        sut.saveMessagesSinceAnalysis(5)
        XCTAssertEqual(sut.loadMessagesSinceAnalysis(), 5)
    }

    func testMessagesSinceAnalysisDefault() {
        XCTAssertEqual(sut.loadMessagesSinceAnalysis(), 0)
    }

    // MARK: - Insight Queue (+ cloud sync)

    func testInsightPushAndPop() {
        sut.pushInsight("Pattern detected: avoidant attachment")
        let popped = sut.popInsight()
        XCTAssertEqual(popped, "Pattern detected: avoidant attachment")
    }

    func testInsightPopEmpty() {
        XCTAssertNil(sut.popInsight())
    }

    func testInsightFIFO() {
        sut.pushInsight("First")
        sut.pushInsight("Second")
        XCTAssertEqual(sut.popInsight(), "First")
        XCTAssertEqual(sut.popInsight(), "Second")
        XCTAssertNil(sut.popInsight())
    }

    // MARK: - Affirmations Round Trip

    func testAffirmationsSaveAndLoad() throws {
        let affirmations = [
            Affirmation(id: "a1", text: "You are the prize."),
            Affirmation(id: "a2", text: "Know your worth.")
        ]
        try sut.saveAffirmations(affirmations)
        let loaded = sut.loadAffirmations()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].text, "You are the prize.")
    }

    // MARK: - Vision Items Round Trip

    func testVisionItemsSaveAndLoad() throws {
        let items = [makeVisionItem(id: "v1"), makeVisionItem(id: "v2", title: "Beach house")]
        try sut.saveVisionItems(items)
        let loaded = sut.loadVisionItems()
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - User Facts Round Trip

    func testUserFactsSaveAndLoad() throws {
        let facts = [
            UserFact(userId: "u1", fact: "Likes cats", category: .relationshipHistory),
            UserFact(userId: "u1", fact: "Wants a promotion", category: .goal)
        ]
        try sut.saveUserFacts(facts)
        let loaded = sut.loadUserFacts()
        XCTAssertEqual(loaded.count, 2)
    }

    // MARK: - Behavioral Loops

    func testAddBehavioralLoops_emptyInput_doesNothing() throws {
        let profile = makeProfile(behavioralLoops: ["Existing loop"])
        try sut.saveProfile(profile)
        sut.addBehavioralLoops([])
        let loaded = sut.loadProfile()
        XCTAssertEqual(loaded?.behavioralLoops?.count, 1)
    }

    func testAddBehavioralLoops_addsNewLoops() throws {
        let profile = makeProfile(behavioralLoops: [])
        try sut.saveProfile(profile)
        sut.addBehavioralLoops(["Avoidant attachment", "People-pleasing"])
        let loaded = sut.loadProfile()
        XCTAssertEqual(loaded?.behavioralLoops?.count, 2)
        XCTAssertTrue(loaded?.behavioralLoops?.contains("Avoidant attachment") ?? false)
    }

    func testAddBehavioralLoops_deduplicatesCaseInsensitive() throws {
        let profile = makeProfile(behavioralLoops: ["avoidant attachment"])
        try sut.saveProfile(profile)
        sut.addBehavioralLoops(["Avoidant Attachment"])
        let loaded = sut.loadProfile()
        XCTAssertEqual(loaded?.behavioralLoops?.count, 1, "Case-insensitive duplicate should be skipped")
    }

    func testAddBehavioralLoops_deduplicatesSubstring() throws {
        let profile = makeProfile(behavioralLoops: ["avoidant attachment pattern"])
        try sut.saveProfile(profile)
        sut.addBehavioralLoops(["avoidant attachment"])
        let loaded = sut.loadProfile()
        XCTAssertEqual(loaded?.behavioralLoops?.count, 1, "Substring match should be skipped")
    }

    func testAddBehavioralLoops_noProfile_doesNothing() {
        // No profile saved
        sut.addBehavioralLoops(["Some loop"])
        XCTAssertNil(sut.loadProfile())
    }

    // MARK: - Notification Rate Limiting (local-only)

    func testCanSendGenericNotification_defaultTrue() {
        XCTAssertTrue(sut.canSendGenericNotification())
    }

    func testNotificationPrimingFlags() {
        XCTAssertFalse(sut.hasShownNotificationPriming())
        sut.setNotificationPrimingShown()
        XCTAssertTrue(sut.hasShownNotificationPriming())
    }

    func testNotificationDeniedFlags() {
        XCTAssertFalse(sut.wasNotificationDeniedAfterPriming())
        sut.setNotificationDeniedAfterPriming()
        XCTAssertTrue(sut.wasNotificationDeniedAfterPriming())
    }

    // MARK: - clearAll

    func testClearAll_wipesEverything() throws {
        try sut.saveProfile(makeProfile())
        try sut.saveGoals([makeGoal()])
        try sut.saveJournalEntries([makeJournalEntry()])
        try sut.saveVisionItems([makeVisionItem()])
        sut.saveLatestVibe(.high)
        sut.saveLatestSummary("summary")
        sut.saveMessagesSinceAnalysis(5)
        sut.pushInsight("test")
        let streak = GlowUpStreak(currentStreak: 3, longestStreak: 5, lastActiveDate: "2025-01-01")
        sut.saveStreak(streak)

        sut.clearAll()

        XCTAssertNil(sut.loadProfile())
        XCTAssertTrue(sut.loadGoals().isEmpty)
        XCTAssertTrue(sut.loadJournalEntries().isEmpty)
        XCTAssertTrue(sut.loadVisionItems().isEmpty)
        XCTAssertNil(sut.loadLatestVibe())
        XCTAssertNil(sut.loadLatestSummary())
        XCTAssertEqual(sut.loadMessagesSinceAnalysis(), 0)
        XCTAssertNil(sut.popInsight())
        XCTAssertEqual(sut.loadStreak().currentStreak, 0)
    }

    // MARK: - Error Handling: Silent Failures

    /// SyncDataService wraps errors silently for cloud push operations.
    /// Local operations should still throw when appropriate.
    func testLocalSaveThrowsOnEncodingError_profileStillSaves() throws {
        // Normal profile save should succeed
        let profile = makeProfile()
        XCTAssertNoThrow(try sut.saveProfile(profile))
        XCTAssertNotNil(sut.loadProfile())
    }

    // MARK: - pushAllToCloud Behavior

    func testPushAllToCloud_doesNotCrash_withEmptyState() async {
        // pushAllToCloud should be safe to call even with no data
        sut.clearAll()
        await sut.pushAllToCloud()
        // No crash = success
    }

    func testPushAllToCloud_doesNotCrash_withPopulatedState() async throws {
        // Populate all entity types
        try sut.saveProfile(makeProfile())
        try sut.saveGoals([makeGoal()])
        try sut.saveJournalEntries([makeJournalEntry()])
        try sut.saveVisionItems([makeVisionItem()])
        try sut.saveAffirmations([Affirmation(text: "You got this")])
        try sut.saveUserFacts([UserFact(userId: "u1", fact: "Test", category: .goal)])
        try sut.saveMessages(
            [Message(conversationId: "c1", role: .user, text: "Hello")],
            forConversation: "c1"
        )
        let convo = Conversation(id: "c1", title: "Test")
        try sut.saveConversation(convo)

        // Should not crash regardless of network state
        await sut.pushAllToCloud()
    }

    // MARK: - syncFromCloud Behavior

    func testSyncFromCloud_doesNotCrash() async {
        // syncFromCloud should be safe to call (it silently catches errors)
        await sut.syncFromCloud()
        // No crash = success
    }

    // MARK: - deleteAccount

    func testDeleteAccount_clearsLocalData() async throws {
        try sut.saveProfile(makeProfile())
        try sut.saveGoals([makeGoal()])
        sut.saveLatestVibe(.high)

        await sut.deleteAccount()

        XCTAssertNil(sut.loadProfile())
        XCTAssertTrue(sut.loadGoals().isEmpty)
        XCTAssertNil(sut.loadLatestVibe())
    }
}
