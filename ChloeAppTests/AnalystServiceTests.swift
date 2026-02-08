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

    // MARK: - Per-Extraction Cap (Phase 3)

    func testMergeFacts_capsAt10PerExtraction() {
        let extractedFacts = (0..<15).map {
            ExtractedFact(fact: "Fact \($0)", category: .goal)
        }
        let result = makeResult(facts: extractedFacts)

        let merged = sut.mergeNewFacts(
            existing: [],
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 10, "Should cap at 10 facts per extraction")
    }

    // MARK: - Total Facts Cap (Phase 1)

    func testMergeFacts_capsAt50Total() {
        // Start with 48 existing facts
        let existing = (0..<48).map { makeFact(fact: "Existing fact \($0)") }
        let result = makeResult(facts: [
            ExtractedFact(fact: "New fact A", category: .goal),
            ExtractedFact(fact: "New fact B", category: .goal),
            ExtractedFact(fact: "New fact C", category: .goal),
            ExtractedFact(fact: "New fact D", category: .goal)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertLessThanOrEqual(merged.count, 50, "Should cap at 50 total facts")
    }

    func testMergeFacts_dropsOldestWhenOverCap() {
        // Fill to 49 + add 3 new = 52 → should drop oldest 2
        let existing = (0..<49).map { makeFact(fact: "Old fact \($0)") }
        let result = makeResult(facts: [
            ExtractedFact(fact: "New A", category: .goal),
            ExtractedFact(fact: "New B", category: .goal),
            ExtractedFact(fact: "New C", category: .goal)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 50)
        // Oldest facts should have been dropped (suffix keeps newest)
        XCTAssertEqual(merged.last?.fact, "New C")
    }

    // MARK: - Case-Insensitive Dedup (Phase 1)

    func testMergeFacts_caseInsensitiveDedup() {
        let existing = [makeFact(fact: "She likes cats")]
        let result = makeResult(facts: [
            ExtractedFact(fact: "SHE LIKES CATS", category: .relationshipHistory)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 1, "Case-insensitive duplicate should be skipped")
    }

    // MARK: - Substring Dedup (Phase 1)

    func testMergeFacts_substringDedup_newContainsExisting() {
        let existing = [makeFact(fact: "She likes cats")]
        let result = makeResult(facts: [
            ExtractedFact(fact: "she likes cats and dogs", category: .relationshipHistory)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 1, "Substring match (new contains existing) should be skipped")
    }

    func testMergeFacts_substringDedup_existingContainsNew() {
        let existing = [makeFact(fact: "She likes cats and dogs")]
        let result = makeResult(facts: [
            ExtractedFact(fact: "she likes cats", category: .relationshipHistory)
        ])

        let merged = sut.mergeNewFacts(
            existing: existing,
            from: result,
            userId: "user1",
            sourceMessageId: "msg2"
        )

        XCTAssertEqual(merged.count, 1, "Substring match (existing contains new) should be skipped")
    }
}
