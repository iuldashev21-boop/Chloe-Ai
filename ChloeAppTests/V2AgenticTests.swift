import XCTest
@testable import ChloeApp

/// Unit tests for V2 Agentic Infrastructure
/// Tests Router + Strategist JSON pipeline components
final class V2AgenticTests: XCTestCase {

    // MARK: - Router Classification Tests

    func testRouterClassification_decodeCrisisBreakup() throws {
        let json = """
        {
            "category": "CRISIS_BREAKUP",
            "urgency": "HIGH",
            "reasoning": "User is in emotional distress after being blocked"
        }
        """

        let data = json.data(using: .utf8)!
        let classification = try JSONDecoder().decode(RouterClassification.self, from: data)

        XCTAssertEqual(classification.category, .crisisBreakup)
        XCTAssertEqual(classification.urgency, .high)
        XCTAssertTrue(classification.reasoning.contains("blocked"))
    }

    func testRouterClassification_decodeDatingEarly() throws {
        let json = """
        {
            "category": "DATING_EARLY",
            "urgency": "MEDIUM",
            "reasoning": "User is navigating early dating situation with mixed signals"
        }
        """

        let data = json.data(using: .utf8)!
        let classification = try JSONDecoder().decode(RouterClassification.self, from: data)

        XCTAssertEqual(classification.category, .datingEarly)
        XCTAssertEqual(classification.urgency, .medium)
    }

    func testRouterClassification_decodeRelationshipEstablished() throws {
        let json = """
        {
            "category": "RELATIONSHIP_ESTABLISHED",
            "urgency": "LOW",
            "reasoning": "User is in committed relationship seeking advice"
        }
        """

        let data = json.data(using: .utf8)!
        let classification = try JSONDecoder().decode(RouterClassification.self, from: data)

        XCTAssertEqual(classification.category, .relationshipEstablished)
        XCTAssertEqual(classification.urgency, .low)
    }

    func testRouterClassification_decodeSelfImprovement() throws {
        let json = """
        {
            "category": "SELF_IMPROVEMENT",
            "urgency": "LOW",
            "reasoning": "User wants to work on personal growth"
        }
        """

        let data = json.data(using: .utf8)!
        let classification = try JSONDecoder().decode(RouterClassification.self, from: data)

        XCTAssertEqual(classification.category, .selfImprovement)
    }

    func testRouterClassification_decodeSafetyRisk() throws {
        let json = """
        {
            "category": "SAFETY_RISK",
            "urgency": "HIGH",
            "reasoning": "User expressing concerning statements"
        }
        """

        let data = json.data(using: .utf8)!
        let classification = try JSONDecoder().decode(RouterClassification.self, from: data)

        XCTAssertEqual(classification.category, .safetyRisk)
        XCTAssertEqual(classification.urgency, .high)
    }

    // MARK: - StrategyOption Tests

    func testStrategyOption_decodeWithOutcomeKey() throws {
        let json = """
        {
            "label": "Option A",
            "action": "Do nothing and wait",
            "outcome": "He texts within 48 hours"
        }
        """

        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(StrategyOption.self, from: data)

        XCTAssertEqual(option.label, "Option A")
        XCTAssertEqual(option.action, "Do nothing and wait")
        XCTAssertEqual(option.outcome, "He texts within 48 hours")
    }

    func testStrategyOption_decodeWithPredictedOutcomeKey() throws {
        let json = """
        {
            "label": "Option B",
            "action": "Post the thirst trap",
            "predicted_outcome": "He reacts but doesn't text"
        }
        """

        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(StrategyOption.self, from: data)

        XCTAssertEqual(option.label, "Option B")
        XCTAssertEqual(option.action, "Post the thirst trap")
        XCTAssertEqual(option.outcome, "He reacts but doesn't text")
    }

    func testStrategyOption_decodeWithMissingOutcome() throws {
        let json = """
        {
            "label": "Option C",
            "action": "Something else"
        }
        """

        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(StrategyOption.self, from: data)

        XCTAssertEqual(option.label, "Option C")
        XCTAssertEqual(option.action, "Something else")
        XCTAssertEqual(option.outcome, "") // Should default to empty string
    }

    func testStrategyOption_encodeAlwaysUsesPredictedOutcome() throws {
        let option = StrategyOption(label: "Test", action: "Test action", outcome: "Test outcome")

        let data = try JSONEncoder().encode(option)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("predicted_outcome"))
        XCTAssertFalse(json.contains("\"outcome\"")) // Should not have standalone "outcome" key
    }

    func testStrategyOption_identifiable() {
        let option = StrategyOption(label: "Test Label", action: "Test", outcome: "")
        XCTAssertEqual(option.id, "Test Label") // id is derived from label
    }

    // MARK: - StrategistResponse Tests

    func testStrategistResponse_decodeWithOptions() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "HIGH",
                "man_behavior_analysis": "He is showing classic orbiting behavior",
                "strategy_selection": "Use Efficiency Mode with A/B options"
            },
            "response": {
                "text": "Let me break this down for you...",
                "options": [
                    {
                        "label": "Option A - High Value",
                        "action": "Mirror his energy",
                        "predicted_outcome": "He steps up"
                    },
                    {
                        "label": "Option B - Low Value",
                        "action": "Double text",
                        "predicted_outcome": "He pulls back"
                    }
                ]
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)

        XCTAssertEqual(response.internalThought.userVibe, "HIGH")
        XCTAssertTrue(response.internalThought.manBehaviorAnalysis.contains("orbiting"))
        XCTAssertEqual(response.response.text, "Let me break this down for you...")
        XCTAssertNotNil(response.response.options)
        XCTAssertEqual(response.response.options?.count, 2)
        XCTAssertEqual(response.response.options?[0].label, "Option A - High Value")
    }

    func testStrategistResponse_decodeWithoutOptions() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "LOW",
                "man_behavior_analysis": "Crisis situation - no game theory needed",
                "strategy_selection": "Supportive grounding"
            },
            "response": {
                "text": "I'm so sorry you're going through this. First, breathe with me..."
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)

        XCTAssertEqual(response.internalThought.userVibe, "LOW")
        XCTAssertNil(response.response.options)
        XCTAssertTrue(response.response.text.contains("breathe"))
    }

    func testStrategistResponse_decodeWithEmptyOptions() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "MEDIUM",
                "man_behavior_analysis": "N/A",
                "strategy_selection": "General support"
            },
            "response": {
                "text": "Here's what I think...",
                "options": []
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)

        XCTAssertNotNil(response.response.options)
        XCTAssertEqual(response.response.options?.count, 0)
    }

    // MARK: - RouterMetadata Tests

    func testRouterMetadata_encode() throws {
        let metadata = RouterMetadata(
            internalThought: "User vibe: HIGH\nAnalysis: Testing",
            routerMode: "DATING_EARLY",
            selectedOption: "Option A"
        )

        let data = try JSONEncoder().encode(metadata)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("internal_thought"))
        XCTAssertTrue(json.contains("router_mode"))
        XCTAssertTrue(json.contains("selected_option"))
    }

    func testRouterMetadata_decode() throws {
        let json = """
        {
            "internal_thought": "Vibe: MEDIUM",
            "router_mode": "CRISIS_BREAKUP",
            "selected_option": null
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(RouterMetadata.self, from: data)

        XCTAssertEqual(metadata.routerMode, "CRISIS_BREAKUP")
        XCTAssertNil(metadata.selectedOption)
    }

    // MARK: - MessageContentType Tests

    func testMessageContentType_text() {
        let type = MessageContentType.text
        XCTAssertEqual(type.rawValue, "text")
    }

    func testMessageContentType_optionPair() {
        let type = MessageContentType.optionPair
        XCTAssertEqual(type.rawValue, "option_pair")
    }

    // MARK: - Integration: V2 Mode Flag

    func testV2AgenticMode_isEnabled() {
        // Verify the V2 mode flag is set correctly
        XCTAssertTrue(V2_AGENTIC_MODE, "V2 Agentic Mode should be enabled for production")
    }
}

// MARK: - Integration Tests (Require API Key)

final class V2AgenticIntegrationTests: XCTestCase {

    var geminiService: GeminiService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        geminiService = GeminiService.shared

        // Skip if no API key configured
        let apiKeyExists = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKeyExists == nil || apiKeyExists?.isEmpty == true, "Skipping - No API key configured")
    }

    // MARK: - Router Classification Integration

    func testRouter_classifyBreakupMessage() async throws {
        let message = "He just blocked me everywhere. I can't stop crying, I feel like I can't breathe."

        let classification = try await geminiService.classifyMessage(message: message)

        // Should classify as CRISIS_BREAKUP with HIGH urgency
        XCTAssertEqual(classification.category, .crisisBreakup,
                       "Breakup crisis should be classified as CRISIS_BREAKUP")
        XCTAssertEqual(classification.urgency, .high,
                       "Acute distress should be HIGH urgency")
    }

    func testRouter_classifyDatingMessage() async throws {
        let message = "He hasn't texted in 2 days but he's watching my stories. Should I post a thirst trap?"

        let classification = try await geminiService.classifyMessage(message: message)

        // Should classify as DATING_EARLY
        XCTAssertEqual(classification.category, .datingEarly,
                       "Dating strategy question should be classified as DATING_EARLY")
    }

    func testRouter_classifySelfImprovementMessage() async throws {
        let message = "I want to work on my confidence and stop seeking validation from men."

        let classification = try await geminiService.classifyMessage(message: message)

        // Should classify as SELF_IMPROVEMENT
        XCTAssertEqual(classification.category, .selfImprovement,
                       "Personal growth focus should be classified as SELF_IMPROVEMENT")
    }

    // MARK: - Strategist Response Integration

    func testStrategist_returnsOptionsForDatingQuestion() async throws {
        let messages = [
            Message(conversationId: "test", role: .user, text: "He's being hot and cold. Should I confront him?")
        ]

        let systemPrompt = "You are Chloe. Return JSON with internal_thought and response."

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        // Should have internal thought
        XCTAssertFalse(response.internalThought.userVibe.isEmpty,
                       "Should have user_vibe analysis")
        XCTAssertFalse(response.internalThought.strategySelection.isEmpty,
                       "Should have strategy_selection")

        // Should have response text
        XCTAssertFalse(response.response.text.isEmpty,
                       "Should have response text")
    }

    func testStrategist_noOptionsForCrisis() async throws {
        let messages = [
            Message(conversationId: "test", role: .user, text: "I just found out he cheated. I can't breathe.")
        ]

        // Include router context for CRISIS_BREAKUP
        let systemPrompt = """
        You are Chloe. Return JSON with internal_thought and response.
        <router_context>
          Category: CRISIS_BREAKUP
          Urgency: HIGH
        </router_context>
        For HIGH urgency crisis situations, do NOT provide options. Just support.
        """

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        // Crisis responses should NOT have options (or empty array)
        if let options = response.response.options {
            XCTAssertTrue(options.isEmpty,
                          "Crisis response should not have game theory options")
        }

        // Response should be supportive, not strategic
        let text = response.response.text.lowercased()
        XCTAssertFalse(text.contains("option a") || text.contains("option b"),
                       "Crisis response should not contain A/B options")
    }
}

// MARK: - Behavioral Loops Tests

final class BehavioralLoopsTests: XCTestCase {

    var storageService: SyncDataService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageService = SyncDataService.shared
    }

    func testBehavioralLoops_addNewLoop() {
        // Get initial state
        var profile = storageService.loadProfile() ?? Profile()
        let initialCount = profile.behavioralLoops?.count ?? 0

        // Add a new loop
        storageService.addBehavioralLoops(["Test pattern: User double-texts when anxious"])

        // Verify it was added
        profile = storageService.loadProfile()!
        let newCount = profile.behavioralLoops?.count ?? 0

        XCTAssertGreaterThan(newCount, initialCount,
                             "New loop should be added to profile")
        XCTAssertTrue(profile.behavioralLoops?.contains(where: { $0.contains("double-texts") }) ?? false,
                      "Should contain the added loop")
    }

    func testBehavioralLoops_deduplication() {
        // Add the same loop twice
        let loop = "User seeks validation after arguments"
        storageService.addBehavioralLoops([loop])
        let countAfterFirst = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        storageService.addBehavioralLoops([loop])
        let countAfterSecond = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        XCTAssertEqual(countAfterFirst, countAfterSecond,
                       "Duplicate loops should not be added")
    }

    func testBehavioralLoops_persistence() {
        // Add a unique loop
        let uniqueLoop = "TestLoop_\(UUID().uuidString)"
        storageService.addBehavioralLoops([uniqueLoop])

        // Load fresh and verify
        let profile = storageService.loadProfile()
        XCTAssertTrue(profile?.behavioralLoops?.contains(uniqueLoop) ?? false,
                      "Loop should persist across loads")
    }
}
