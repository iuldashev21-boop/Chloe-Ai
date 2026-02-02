import XCTest
@testable import ChloeApp

final class StreakServiceTests: XCTestCase {

    private let sut = StreakService.shared
    private let storage = StorageService.shared

    override func setUp() {
        super.setUp()
        storage.clearAll()
    }

    override func tearDown() {
        storage.clearAll()
        super.tearDown()
    }

    // MARK: - Helpers

    private func dateString(daysAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return formatter.string(from: date)
    }

    // MARK: - Streak Start

    func testChatStartsStreakFromZero() {
        sut.recordActivity(source: .chat)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 1)
        XCTAssertEqual(streak.lastActiveDate, GlowUpStreak.todayKey())
    }

    // MARK: - Streak Extend

    func testChatExtendsStreak() {
        let yesterday = dateString(daysAgo: 1)
        storage.saveStreak(GlowUpStreak(currentStreak: 3, longestStreak: 3, lastActiveDate: yesterday))
        sut.recordActivity(source: .chat)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 4)
    }

    // MARK: - Idempotent

    func testIdempotent_sameDay() {
        sut.recordActivity(source: .chat)
        let after1 = storage.loadStreak()
        XCTAssertEqual(after1.currentStreak, 1)

        sut.recordActivity(source: .chat)
        let after2 = storage.loadStreak()
        XCTAssertEqual(after2.currentStreak, 1, "Should not increment on same day")
    }

    // MARK: - Streak Reset

    func testStreakResets_after3DayGap() {
        let threeDaysAgo = dateString(daysAgo: 3)
        storage.saveStreak(GlowUpStreak(currentStreak: 5, longestStreak: 5, lastActiveDate: threeDaysAgo))
        sut.recordActivity(source: .chat)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 1, "Gap > 2 days should reset streak")
    }

    // MARK: - Gap Tolerance (skip 1 day)

    func testStreakExtends_with1DayGap() {
        let twoDaysAgo = dateString(daysAgo: 2)
        storage.saveStreak(GlowUpStreak(currentStreak: 3, longestStreak: 3, lastActiveDate: twoDaysAgo))
        sut.recordActivity(source: .chat)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 4, "Gap of 2 days (skipping 1) should extend")
    }

    // MARK: - Journal Rules

    func testJournalCannotStartStreak() {
        sut.recordActivity(source: .journal)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 0, "Journal cannot start a streak from zero")
    }

    func testJournalExtendsExistingStreak() {
        let yesterday = dateString(daysAgo: 1)
        storage.saveStreak(GlowUpStreak(currentStreak: 2, longestStreak: 2, lastActiveDate: yesterday))
        sut.recordActivity(source: .journal)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 3)
    }

    func testJournalCannotRestartBrokenStreak() {
        let threeDaysAgo = dateString(daysAgo: 3)
        storage.saveStreak(GlowUpStreak(currentStreak: 5, longestStreak: 5, lastActiveDate: threeDaysAgo))
        sut.recordActivity(source: .journal)
        let streak = storage.loadStreak()
        // Journal can't restart — streak should remain unchanged
        XCTAssertEqual(streak.currentStreak, 5, "Journal should not reset a broken streak")
        XCTAssertEqual(streak.lastActiveDate, threeDaysAgo, "Journal should not update lastActiveDate on broken streak")
    }

    // MARK: - Longest Streak Tracking

    func testLongestStreakTracked() {
        let yesterday = dateString(daysAgo: 1)
        storage.saveStreak(GlowUpStreak(currentStreak: 4, longestStreak: 4, lastActiveDate: yesterday))
        sut.recordActivity(source: .chat)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 5)
        XCTAssertEqual(streak.longestStreak, 5)
    }

    func testLongestStreakPreservedAfterReset() {
        let threeDaysAgo = dateString(daysAgo: 3)
        storage.saveStreak(GlowUpStreak(currentStreak: 2, longestStreak: 5, lastActiveDate: threeDaysAgo))
        sut.recordActivity(source: .chat)
        let streak = storage.loadStreak()
        XCTAssertEqual(streak.currentStreak, 1)
        XCTAssertEqual(streak.longestStreak, 5, "Longest streak should be preserved")
    }
}
