import XCTest
@testable import ChloeApp

final class DailyUsageTests: XCTestCase {

    private let storage = StorageService.shared

    override func setUp() {
        super.setUp()
        storage.clearAll()
    }

    override func tearDown() {
        storage.clearAll()
        super.tearDown()
    }

    // MARK: - Fresh Usage

    func testFreshUsage_countIsZero() {
        let usage = storage.loadDailyUsage()
        XCTAssertEqual(usage.messageCount, 0)
    }

    // MARK: - Increment

    func testIncrementTo5() throws {
        var usage = DailyUsage(date: DailyUsage.todayKey(), messageCount: 5)
        try storage.saveDailyUsage(usage)
        usage = storage.loadDailyUsage()
        XCTAssertEqual(usage.messageCount, 5)
    }

    func testAtLimit() throws {
        let usage = DailyUsage(date: DailyUsage.todayKey(), messageCount: FREE_DAILY_MESSAGE_LIMIT)
        try storage.saveDailyUsage(usage)
        let loaded = storage.loadDailyUsage()
        XCTAssertEqual(loaded.messageCount, FREE_DAILY_MESSAGE_LIMIT)
        XCTAssertTrue(loaded.messageCount >= FREE_DAILY_MESSAGE_LIMIT)
    }

    // MARK: - Day Rollover

    func testDayRollover_resetsCount() throws {
        let oldUsage = DailyUsage(date: "2024-01-01", messageCount: 5)
        try storage.saveDailyUsage(oldUsage)
        let loaded = storage.loadDailyUsage()
        XCTAssertEqual(loaded.messageCount, 0, "New day should reset count")
        XCTAssertEqual(loaded.date, DailyUsage.todayKey())
    }

    // MARK: - Today Key Format

    func testTodayKey_format() {
        let key = DailyUsage.todayKey()
        // Should match yyyy-MM-dd
        let regex = try? NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2}$"#)
        let range = NSRange(key.startIndex..., in: key)
        XCTAssertNotNil(regex?.firstMatch(in: key, range: range), "todayKey should be yyyy-MM-dd format")
    }

    func testTodayKey_matchesCurrentDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expected = formatter.string(from: Date())
        XCTAssertEqual(DailyUsage.todayKey(), expected)
    }

    // MARK: - Paywall Boundary (5th allowed, 6th blocked)

    func testFifthMessageAllowed() throws {
        // count == 4 means 4 messages sent, 5th should go through
        let usage = DailyUsage(date: DailyUsage.todayKey(), messageCount: 4)
        try storage.saveDailyUsage(usage)
        let loaded = storage.loadDailyUsage()
        XCTAssertTrue(loaded.messageCount < FREE_DAILY_MESSAGE_LIMIT,
                       "5th message (count=4) should still be under limit")
    }

    func testSixthMessageBlocked() throws {
        // count == 5 means 5 messages sent, 6th should be blocked
        let usage = DailyUsage(date: DailyUsage.todayKey(), messageCount: 5)
        try storage.saveDailyUsage(usage)
        let loaded = storage.loadDailyUsage()
        XCTAssertTrue(loaded.messageCount >= FREE_DAILY_MESSAGE_LIMIT,
                       "6th message (count=5) should be at or over limit")
    }
}
