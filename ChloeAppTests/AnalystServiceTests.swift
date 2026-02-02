import XCTest
@testable import ChloeApp

final class AnalystServiceTests: XCTestCase {

    private let sut = AnalystService.shared

    // MARK: - Helpers

    private func makeFact(
        fact: String,
        category: FactCategory = .relationshipHistory,
        isActive: Bool = true
    ) -> UserFact {
        UserFact(
            userId: "user1",
            fact: fact,
            category: category,
            sourceMessageId: "msg1",
            isActive: isActive
        )
    }

    private func makeResult(facts: [ExtractedFact]) -> AnalystResult {
        AnalystResult(
            facts: facts,
            vibeScore: .medium,
            vibeReason: "test",
            summary: "test summary"
        )
    }

    // MARK: - Merging Logic

    func testNewFactAdded() {
        let existing = [makeFact(fact: "She likes cats")]
        let result = makeResult(facts: [
            ExtractedFact(fact: "Her ex was avoidant", category: .relationshipHistory)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(merged[1].fact, "Her ex was avoidant")
        XCTAssertEqual(merged[1].userId, "user1")
        XCTAssertEqual(merged[1].sourceMessageId, "msg2")
        XCTAssertTrue(merged[1].isActive)
        XCTAssertEqual(merged[1].category, .relationshipHistory)
    }

    func testDuplicateActiveFactSkipped() {
        let existing = [makeFact(fact: "She likes cats")]
        let result = makeResult(facts: [
            ExtractedFact(fact: "She likes cats", category: .relationshipHistory)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 1, "Duplicate active fact should be skipped")
    }

    func testDuplicateInactiveFactAdded() {
        let existing = [makeFact(fact: "She likes cats", isActive: false)]
        let result = makeResult(facts: [
            ExtractedFact(fact: "She likes cats", category: .relationshipHistory)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 2, "Inactive duplicate should allow re-adding")
    }

    func testMultipleNewFacts() {
        let existing = [makeFact(fact: "Existing fact")]
        let result = makeResult(facts: [
            ExtractedFact(fact: "New fact 1", category: .goal),
            ExtractedFact(fact: "New fact 2", category: .trigger)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 3)
        XCTAssertEqual(merged[1].category, .goal)
        XCTAssertEqual(merged[2].category, .trigger)
    }

    func testEmptyNewFacts() {
        let existing = [makeFact(fact: "Existing")]
        let result = makeResult(facts: [])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 1)
    }

    func testEmptyExistingFacts() {
        let result = makeResult(facts: [
            ExtractedFact(fact: "Brand new", category: .goal)
        ])

        let merged = sut.mergeNewFacts(
            existing: [],
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].fact, "Brand new")
    }
}
