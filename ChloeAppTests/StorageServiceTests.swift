import XCTest
@testable import ChloeApp

final class StorageServiceTests: XCTestCase {

    private let sut = StorageService.shared

    override func setUp() {
        super.setUp()
        sut.clearAll()
    }

    override func tearDown() {
        sut.clearAll()
        super.tearDown()
    }

    // MARK: - Profile

    func testProfileRoundTrip() throws {
        let profile = Profile(
            id: "p1",
            email: "test@test.com",
            displayName: "Sarah",
            onboardingComplete: true,
            subscriptionTier: .premium
        )
        try sut.saveProfile(profile)
        let loaded = sut.loadProfile()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, "p1")
        XCTAssertEqual(loaded?.email, "test@test.com")
        XCTAssertEqual(loaded?.displayName, "Sarah")
        XCTAssertTrue(loaded?.onboardingComplete ?? false)
        XCTAssertEqual(loaded?.subscriptionTier, .premium)
    }

    func testProfileNotSaved_returnsNil() {
        XCTAssertNil(sut.loadProfile())
    }

    // MARK: - User Facts

    func testUserFactsRoundTrip() throws {
        let facts = [
            UserFact(userId: "u1", fact: "Likes cats", category: .relationshipHistory),
            UserFact(userId: "u1", fact: "Wants promotion", category: .goal)
        ]
        try sut.saveUserFacts(facts)
        let loaded = sut.loadUserFacts()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].fact, "Likes cats")
        XCTAssertEqual(loaded[1].fact, "Wants promotion")
    }

    func testUserFactsEmpty() throws {
        try sut.saveUserFacts([])
        XCTAssertTrue(sut.loadUserFacts().isEmpty)
    }

    // MARK: - Vibe Score

    func testVibeScoreLow() {
        sut.saveLatestVibe(.low)
        XCTAssertEqual(sut.loadLatestVibe(), .low)
    }

    func testVibeScoreHigh() {
        sut.saveLatestVibe(.high)
        XCTAssertEqual(sut.loadLatestVibe(), .high)
    }

    func testVibeScoreNil() {
        XCTAssertNil(sut.loadLatestVibe())
    }

    // MARK: - Latest Summary

    func testLatestSummaryRoundTrip() {
        sut.saveLatestSummary("She discussed her ex.")
        XCTAssertEqual(sut.loadLatestSummary(), "She discussed her ex.")
    }

    func testLatestSummaryNil() {
        XCTAssertNil(sut.loadLatestSummary())
    }

    // MARK: - Notification Priming Flags

    func testNotificationPrimingDefault() {
        XCTAssertFalse(sut.hasShownNotificationPriming())
    }

    func testNotificationPrimingShown() {
        sut.setNotificationPrimingShown()
        XCTAssertTrue(sut.hasShownNotificationPriming())
    }

    func testNotificationDeniedDefault() {
        XCTAssertFalse(sut.wasNotificationDeniedAfterPriming())
    }

    func testNotificationDeniedAfterPriming() {
        sut.setNotificationDeniedAfterPriming()
        XCTAssertTrue(sut.wasNotificationDeniedAfterPriming())
    }

    // MARK: - Daily Usage

    func testDailyUsageFresh() {
        let usage = sut.loadDailyUsage()
        XCTAssertEqual(usage.messageCount, 0)
        XCTAssertEqual(usage.date, DailyUsage.todayKey())
    }

    func testDailyUsageSaveAndLoad() throws {
        let usage = DailyUsage(date: DailyUsage.todayKey(), messageCount: 3)
        try sut.saveDailyUsage(usage)
        let loaded = sut.loadDailyUsage()
        XCTAssertEqual(loaded.messageCount, 3)
    }

    func testDailyUsageDayRollover() throws {
        let yesterday = DailyUsage(date: "2025-01-01", messageCount: 5)
        try sut.saveDailyUsage(yesterday)
        let loaded = sut.loadDailyUsage()
        XCTAssertEqual(loaded.messageCount, 0, "Day rollover should reset count")
        XCTAssertEqual(loaded.date, DailyUsage.todayKey())
    }

    // MARK: - Messages Since Analysis

    func testMessagesSinceAnalysisDefault() {
        XCTAssertEqual(sut.loadMessagesSinceAnalysis(), 0)
    }

    func testMessagesSinceAnalysisRoundTrip() {
        sut.saveMessagesSinceAnalysis(2)
        XCTAssertEqual(sut.loadMessagesSinceAnalysis(), 2)
    }

    // MARK: - Conversations & Messages

    func testSaveAndLoadConversation() throws {
        let convo = Conversation(id: "c1", title: "Chat about dating")
        try sut.saveConversation(convo)
        let loaded = sut.loadConversation(id: "c1")
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.title, "Chat about dating")
    }

    func testSaveAndLoadMessages() throws {
        let messages = [
            Message(id: "m1", conversationId: "c1", role: .user, text: "Hello"),
            Message(id: "m2", conversationId: "c1", role: .chloe, text: "Hey girl")
        ]
        try sut.saveMessages(messages, forConversation: "c1")
        let loaded = sut.loadMessages(forConversation: "c1")
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].text, "Hello")
        XCTAssertEqual(loaded[1].text, "Hey girl")
    }

    func testDeleteConversation() throws {
        let convo = Conversation(id: "c1", title: "Test")
        try sut.saveConversation(convo)
        let messages = [Message(id: "m1", conversationId: "c1", role: .user, text: "Hi")]
        try sut.saveMessages(messages, forConversation: "c1")

        sut.deleteConversation(id: "c1")

        XCTAssertNil(sut.loadConversation(id: "c1"))
        XCTAssertTrue(sut.loadMessages(forConversation: "c1").isEmpty)
    }

    func testRenameConversation() throws {
        let convo = Conversation(id: "c1", title: "Old Title")
        try sut.saveConversation(convo)
        try sut.renameConversation(id: "c1", newTitle: "New Title")
        XCTAssertEqual(sut.loadConversation(id: "c1")?.title, "New Title")
    }

    func testToggleConversationStar() throws {
        let convo = Conversation(id: "c1", title: "Test", starred: false)
        try sut.saveConversation(convo)
        XCTAssertFalse(sut.loadConversation(id: "c1")?.starred ?? true)

        try sut.toggleConversationStar(id: "c1")
        XCTAssertTrue(sut.loadConversation(id: "c1")?.starred ?? false)

        try sut.toggleConversationStar(id: "c1")
        XCTAssertFalse(sut.loadConversation(id: "c1")?.starred ?? true)
    }

    // MARK: - Streak

    func testStreakRoundTrip() {
        let streak = GlowUpStreak(currentStreak: 5, longestStreak: 10, lastActiveDate: "2025-06-01")
        sut.saveStreak(streak)
        let loaded = sut.loadStreak()
        XCTAssertEqual(loaded.currentStreak, 5)
        XCTAssertEqual(loaded.longestStreak, 10)
        XCTAssertEqual(loaded.lastActiveDate, "2025-06-01")
    }

    func testStreakDefault() {
        let streak = sut.loadStreak()
        XCTAssertEqual(streak.currentStreak, 0)
        XCTAssertEqual(streak.longestStreak, 0)
        XCTAssertEqual(streak.lastActiveDate, "")
    }

    // MARK: - clearAll

    func testClearAll() throws {
        try sut.saveProfile(Profile(id: "p1", email: "e", displayName: "d"))
        sut.saveLatestVibe(.high)
        sut.saveLatestSummary("summary")
        sut.setNotificationPrimingShown()
        sut.saveMessagesSinceAnalysis(5)
        sut.saveStreak(GlowUpStreak(currentStreak: 3))
        let convo = Conversation(id: "c1", title: "T")
        try sut.saveConversation(convo)
        try sut.saveMessages([Message(role: .user, text: "hi")], forConversation: "c1")
        sut.pushInsight("test insight")

        sut.clearAll()

        XCTAssertNil(sut.loadProfile())
        XCTAssertNil(sut.loadLatestVibe())
        XCTAssertNil(sut.loadLatestSummary())
        XCTAssertFalse(sut.hasShownNotificationPriming())
        XCTAssertEqual(sut.loadMessagesSinceAnalysis(), 0)
        XCTAssertEqual(sut.loadStreak().currentStreak, 0)
        XCTAssertTrue(sut.loadConversations().isEmpty)
        XCTAssertNil(sut.popInsight())
    }
}
