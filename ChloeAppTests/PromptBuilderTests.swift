import XCTest
@testable import ChloeApp

final class PromptBuilderTests: XCTestCase {

    override func setUp() {
        super.setUp()
        StorageService.shared.clearAll()
    }

    override func tearDown() {
        StorageService.shared.clearAll()
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeArchetype(
        label: String = "The Queen",
        blend: String = "The Queen / The Siren",
        description: String = "Regal power meets magnetic allure"
    ) -> UserArchetype {
        UserArchetype(
            primary: .queen,
            secondary: .siren,
            label: label,
            blend: blend,
            description: description
        )
    }

    // MARK: - Template Variable Injection

    func testUserNameReplaced() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Sarah",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("Sarah"))
        XCTAssertFalse(prompt.contains("{{user_name}}"))
    }

    func testEmptyNameFallsToBabe() {
        let prompt = buildPersonalizedPrompt(
            displayName: "",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("babe"))
        XCTAssertFalse(prompt.contains("{{user_name}}"))
    }

    func testArchetypeLabelReplaced() {
        let archetype = makeArchetype(label: "The Queen")
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: archetype
        )
        XCTAssertTrue(prompt.contains("The Queen"))
        XCTAssertFalse(prompt.contains("{{archetype_label}}"))
    }

    func testArchetypeLabelNilDefault() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("Not determined yet"))
        XCTAssertFalse(prompt.contains("{{archetype_label}}"))
    }

    func testArchetypeBlendReplaced() {
        let archetype = makeArchetype(blend: "The Queen / The Siren")
        let prompt = buildAffirmationPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: archetype
        )
        XCTAssertTrue(prompt.contains("The Queen / The Siren"))
        XCTAssertFalse(prompt.contains("{{archetype_blend}}"))
    }

    func testRelationshipStatusDefault() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("Not shared yet"))
        XCTAssertFalse(prompt.contains("{{relationship_status}}"))
    }

    // MARK: - Vibe Mode Gating

    func testVibeModeLow_alwaysBigSister() {
        StorageService.shared.saveLatestVibe(.low)
        for _ in 0..<50 {
            let prompt = buildPersonalizedPrompt(
                displayName: "Test",
                preferences: nil,
                archetype: nil
            )
            XCTAssertTrue(prompt.contains("CURRENT MODE: THE BIG SISTER"))
            XCTAssertFalse(prompt.contains("CURRENT MODE: THE SIREN"))
            XCTAssertFalse(prompt.contains("CURRENT MODE: THE GIRL"))
        }
    }

    func testVibeModeHigh_sirenOrGirl() {
        StorageService.shared.saveLatestVibe(.high)
        var sirenCount = 0
        var girlCount = 0
        let runs = 200
        for _ in 0..<runs {
            let prompt = buildPersonalizedPrompt(
                displayName: "Test",
                preferences: nil,
                archetype: nil
            )
            if prompt.contains("CURRENT MODE: THE SIREN") { sirenCount += 1 }
            if prompt.contains("CURRENT MODE: THE GIRL") { girlCount += 1 }
        }
        // Both modes should appear at least once in 200 runs
        XCTAssertGreaterThan(sirenCount, 0, "Expected THE SIREN to appear at least once")
        XCTAssertGreaterThan(girlCount, 0, "Expected THE GIRL to appear at least once")
        XCTAssertEqual(sirenCount + girlCount, runs)
    }

    func testVibeModeMedium_bigSisterOrSiren() {
        StorageService.shared.saveLatestVibe(.medium)
        var bigSisterCount = 0
        var sirenCount = 0
        let runs = 200
        for _ in 0..<runs {
            let prompt = buildPersonalizedPrompt(
                displayName: "Test",
                preferences: nil,
                archetype: nil
            )
            if prompt.contains("CURRENT MODE: THE BIG SISTER") { bigSisterCount += 1 }
            if prompt.contains("CURRENT MODE: THE SIREN") { sirenCount += 1 }
        }
        XCTAssertGreaterThan(bigSisterCount, 0, "Expected THE BIG SISTER to appear at least once")
        XCTAssertGreaterThan(sirenCount, 0, "Expected THE SIREN to appear at least once")
        XCTAssertEqual(bigSisterCount + sirenCount, runs)
    }

    func testVibeModeNil_sameAsMedium() {
        // clearAll already ensures no vibe is saved (nil)
        var bigSisterCount = 0
        var sirenCount = 0
        let runs = 200
        for _ in 0..<runs {
            let prompt = buildPersonalizedPrompt(
                displayName: "Test",
                preferences: nil,
                archetype: nil
            )
            if prompt.contains("CURRENT MODE: THE BIG SISTER") { bigSisterCount += 1 }
            if prompt.contains("CURRENT MODE: THE SIREN") { sirenCount += 1 }
        }
        XCTAssertGreaterThan(bigSisterCount, 0)
        XCTAssertGreaterThan(sirenCount, 0)
        XCTAssertEqual(bigSisterCount + sirenCount, runs)
    }

    // MARK: - Output Integrity

    func testNoPlaceholdersRemain() {
        let archetype = makeArchetype()
        StorageService.shared.saveLatestVibe(.medium)
        let prompt = buildPersonalizedPrompt(
            displayName: "TestUser",
            preferences: nil,
            archetype: archetype
        )
        XCTAssertFalse(prompt.contains("{{"), "Unresolved placeholder found in prompt")
    }

    func testSystemPromptContainsChloeFramework() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("CHLOE"))
        XCTAssertTrue(prompt.contains("BIOLOGY VS. EFFICIENCY"))
        XCTAssertTrue(prompt.contains("DECENTERING"))
        XCTAssertTrue(prompt.contains("MULTIPLIER EFFECT"))
    }

    func testFewShotExamplesPresent() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("FEW-SHOT EXAMPLES"))
        XCTAssertTrue(prompt.contains("Placeholder"))
    }

    // MARK: - Affirmation Prompt

    func testAffirmationPromptInjection() {
        let archetype = makeArchetype(blend: "The Rebel / The Muse")
        let prompt = buildAffirmationPrompt(
            displayName: "Luna",
            preferences: nil,
            archetype: archetype
        )
        XCTAssertTrue(prompt.contains("Luna"))
        XCTAssertTrue(prompt.contains("The Rebel / The Muse"))
        XCTAssertFalse(prompt.contains("{{"))
    }

    // MARK: - Topic Gate

    func testTopicGateSectionPresent() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("<contextual_application_logic>"))
        XCTAssertTrue(prompt.contains("ROMANTIC / DATING"))
        XCTAssertTrue(prompt.contains("CAREER / SELF"))
        XCTAssertTrue(prompt.contains("FRIENDSHIP / FAMILY"))
        XCTAssertTrue(prompt.contains("AMBIGUOUS"))
    }

    // MARK: - Vocabulary Control

    func testVocabularyControlSectionPresent() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("<vocabulary_control>"))
        XCTAssertTrue(prompt.contains("Chloe-ism"))
        XCTAssertTrue(prompt.contains("Vibe > vocabulary"))
    }

    // MARK: - GENTLE SUPPORT Mode

    func testGentleSupportModePresent() {
        let prompt = buildPersonalizedPrompt(
            displayName: "Test",
            preferences: nil,
            archetype: nil
        )
        XCTAssertTrue(prompt.contains("GENTLE SUPPORT"))
        XCTAssertTrue(prompt.contains("The Anchor"))
    }
}
