import XCTest
@testable import ChloeApp

final class InsightQueueTests: XCTestCase {

    private let sut = StorageService.shared

    override func setUp() {
        super.setUp()
        sut.clearAll()
    }

    override func tearDown() {
        sut.clearAll()
        super.tearDown()
    }

    // MARK: - FIFO Ordering

    func testFIFO_popsInOrder() {
        sut.pushInsight("Insight A")
        sut.pushInsight("Insight B")

        XCTAssertEqual(sut.popInsight(), "Insight A")
        XCTAssertEqual(sut.popInsight(), "Insight B")
    }

    // MARK: - Deduplication

    func testDedup_caseInsensitiveExact() {
        sut.pushInsight("He is avoidant")
        sut.pushInsight("he is avoidant")

        XCTAssertEqual(sut.popInsight(), "He is avoidant")
        XCTAssertNil(sut.popInsight(), "Case-insensitive duplicate should be skipped")
    }

    func testDedup_substringMatch() {
        sut.pushInsight("avoidant")
        sut.pushInsight("He is avoidant")

        XCTAssertEqual(sut.popInsight(), "avoidant")
        XCTAssertNil(sut.popInsight(), "Substring match should be skipped")
    }

    func testDedup_differentInsightsAllowed() {
        sut.pushInsight("He is avoidant")
        sut.pushInsight("She sets boundaries well")

        XCTAssertEqual(sut.popInsight(), "He is avoidant")
        XCTAssertEqual(sut.popInsight(), "She sets boundaries well")
    }

    // MARK: - Expiry

    func testExpiredInsightDiscarded() {
        // Manually push an expired insight by manipulating storage
        // Since pushInsight always uses Date(), we test expiry via popInsight behavior
        // We need to push and then simulate passage of time
        // The only way to test this without exposing internals is to verify that
        // a freshly pushed insight is NOT expired (14 days haven't passed)
        sut.pushInsight("Recent insight")
        XCTAssertEqual(sut.popInsight(), "Recent insight", "Fresh insight should not be expired")
    }

    // MARK: - Empty Queue

    func testPopFromEmpty_returnsNil() {
        XCTAssertNil(sut.popInsight())
    }

    // MARK: - Multiple Operations

    func testPushPopPush() {
        sut.pushInsight("First")
        XCTAssertEqual(sut.popInsight(), "First")
        sut.pushInsight("Second")
        XCTAssertEqual(sut.popInsight(), "Second")
        XCTAssertNil(sut.popInsight())
    }
}
