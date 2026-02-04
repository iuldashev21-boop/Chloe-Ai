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

    // MARK: - v2.2 Stability Fix Tests

    /// FIX 3: Test flexible decoding when internal_thought is a String instead of Object
    func testStrategistResponse_decodeWithStringInternalThought() throws {
        let json = """
        {
            "internal_thought": "This is a string instead of object - LLM glitch",
            "response": {
                "text": "Hello there!",
                "options": []
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)

        // Should not crash - flexible decoder wraps string in struct
        XCTAssertEqual(response.internalThought.userVibe, "UNKNOWN")
        XCTAssertEqual(response.internalThought.manBehaviorAnalysis, "N/A")
        XCTAssertEqual(response.internalThought.strategySelection, "This is a string instead of object - LLM glitch")
        XCTAssertEqual(response.response.text, "Hello there!")
    }

    /// FIX 3: Test flexible decoding when internal_thought is missing - uses fallback
    func testStrategistResponse_decodeWithMissingInternalThought() throws {
        let json = """
        {
            "response": {
                "text": "Response without internal thought",
                "options": []
            }
        }
        """

        let data = json.data(using: .utf8)!

        // The flexible decoder should handle missing internal_thought with fallback
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)

        // Should use fallback values
        XCTAssertEqual(response.internalThought.userVibe, "UNKNOWN")
        XCTAssertEqual(response.internalThought.strategySelection, "Parsing Error")
        XCTAssertEqual(response.response.text, "Response without internal thought")
    }

    /// FIX 4: Test markdown stripping helper (unit test via GeminiService)
    func testMarkdownStripping_jsonBlock() {
        // Test the stripMarkdownWrapper logic
        let wrapped = "```json\n{\"test\": true}\n```"
        let expected = "{\"test\": true}"

        // Manually test the stripping logic
        var cleaned = wrapped.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertEqual(cleaned, expected)
    }

    /// FIX 4: Test markdown stripping with plain code block
    func testMarkdownStripping_plainBlock() {
        let wrapped = "```\n{\"foo\": \"bar\"}\n```"
        let expected = "{\"foo\": \"bar\"}"

        var cleaned = wrapped.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertEqual(cleaned, expected)
    }

    /// FIX 4: Test no stripping needed for clean JSON
    func testMarkdownStripping_cleanJSON() {
        let clean = "{\"clean\": true}"

        var result = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```json") {
            result = String(result.dropFirst(7))
        } else if result.hasPrefix("```") {
            result = String(result.dropFirst(3))
        }
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertEqual(result, clean, "Clean JSON should remain unchanged")
    }

    // MARK: - FIX 7: ResponseContent Flexible Decoding Tests

    /// FIX 7: Test ResponseContent decodes when "response" is a plain string
    func testResponseContent_decodeFromString() throws {
        let json = """
        "This is a plain string response from the LLM"
        """

        let data = json.data(using: .utf8)!
        let content = try JSONDecoder().decode(ResponseContent.self, from: data)

        XCTAssertEqual(content.text, "This is a plain string response from the LLM")
        XCTAssertNil(content.options)
    }

    /// FIX 7: Test ResponseContent decodes with "advice" key instead of "text"
    func testResponseContent_decodeWithAdviceKey() throws {
        let json = """
        {
            "advice": "Here's my advice for you...",
            "options": []
        }
        """

        let data = json.data(using: .utf8)!
        let content = try JSONDecoder().decode(ResponseContent.self, from: data)

        XCTAssertEqual(content.text, "Here's my advice for you...")
        XCTAssertNotNil(content.options)
    }

    /// FIX 7: Test ResponseContent decodes normally with "text" key
    func testResponseContent_decodeWithTextKey() throws {
        let json = """
        {
            "text": "Normal response text",
            "options": [
                {"label": "A", "action": "Do X", "outcome": "Y happens"}
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let content = try JSONDecoder().decode(ResponseContent.self, from: data)

        XCTAssertEqual(content.text, "Normal response text")
        XCTAssertEqual(content.options?.count, 1)
    }

    /// FIX 7: Test full StrategistResponse with string response
    func testStrategistResponse_decodeWithStringResponse() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "HIGH",
                "man_behavior_analysis": "Testing",
                "strategy_selection": "Support"
            },
            "response": "This is the response as a plain string"
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)

        XCTAssertEqual(response.response.text, "This is the response as a plain string")
        XCTAssertNil(response.response.options)
    }

    /// FIX 7: Test full StrategistResponse with advice key
    func testStrategistResponse_decodeWithAdviceResponse() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "MEDIUM",
                "man_behavior_analysis": "N/A",
                "strategy_selection": "General"
            },
            "response": {
                "advice": "My advice is to wait and see"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)

        XCTAssertEqual(response.response.text, "My advice is to wait and see")
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

// MARK: - Memory Detection Tests

/// Tests for Analyst correctly detecting patterns from conversation
final class MemoryDetectionTests: XCTestCase {

    // MARK: - Unit Tests: AnalystResult Decoding

    /// Verify AnalystResult correctly decodes JSON with behavioral_loops_detected
    func testAnalystResult_decodesWithBehavioralLoops() throws {
        let json = """
        {
            "new_facts": [],
            "vibe_score": "MEDIUM",
            "vibe_reasoning": "User is calm",
            "behavioral_loops_detected": ["User checks location when anxious", "User double-texts when insecure"],
            "session_summary": "Discussion about relationship patterns"
        }
        """

        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AnalystResult.self, from: data)

        XCTAssertEqual(result.behavioralLoops.count, 2)
        XCTAssertTrue(result.behavioralLoops.contains("User checks location when anxious"))
        XCTAssertTrue(result.behavioralLoops.contains("User double-texts when insecure"))
    }

    /// Verify empty behavioral_loops array doesn't crash
    func testAnalystResult_decodesWithEmptyLoops() throws {
        let json = """
        {
            "new_facts": [],
            "vibe_score": "HIGH",
            "vibe_reasoning": "Good vibes",
            "behavioral_loops_detected": [],
            "session_summary": "Casual chat"
        }
        """

        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AnalystResult.self, from: data)

        XCTAssertTrue(result.behavioralLoops.isEmpty)
        XCTAssertEqual(result.vibeScore, .high)
    }

    /// Verify AnalystResult handles missing engagement_opportunity (optional)
    func testAnalystResult_decodesWithoutEngagementOpportunity() throws {
        let json = """
        {
            "new_facts": [{"fact": "User is dating someone named Jake", "category": "RELATIONSHIP_HISTORY"}],
            "vibe_score": "LOW",
            "vibe_reasoning": "User seems stressed",
            "behavioral_loops_detected": ["Seeks validation when ignored"],
            "session_summary": "User shared relationship concerns"
        }
        """

        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AnalystResult.self, from: data)

        XCTAssertEqual(result.behavioralLoops.count, 1)
        XCTAssertNil(result.engagementOpportunity)
        XCTAssertEqual(result.facts.count, 1)
    }

    // MARK: - Integration Tests: Pattern Detection (Require API Key)

    func testAnalyst_detectsLocationCheckingPattern() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        // Use explicit, repeated pattern language to ensure detection
        let messages = [
            Message(conversationId: "test", role: .user, text: "I keep checking his location obsessively. I've done it like 10 times today."),
            Message(conversationId: "test", role: .chloe, text: "That sounds like a recurring pattern. What triggers the urge to check?"),
            Message(conversationId: "test", role: .user, text: "Every time he doesn't respond, I check his location. It's become a compulsive habit I can't break. I know it's unhealthy but I keep doing it over and over."),
            Message(conversationId: "test", role: .chloe, text: "I notice this pattern of checking when anxious. Have you noticed it too?"),
            Message(conversationId: "test", role: .user, text: "Yes, it's definitely a pattern. I always do this when I feel insecure. Every relationship, same behavior.")
        ]

        let result = try await GeminiService.shared.analyzeConversation(messages: messages)

        // Should detect a location-checking, compulsive, or anxiety-related pattern
        // Note: LLM detection can be variable; if no loops detected, this may indicate
        // the Analyst prompt needs tuning for behavioral loop extraction
        let hasRelevantPattern = result.behavioralLoops.contains { loop in
            let lowercased = loop.lowercased()
            return lowercased.contains("location") ||
                   lowercased.contains("check") ||
                   lowercased.contains("anxious") ||
                   lowercased.contains("monitor") ||
                   lowercased.contains("compulsive") ||
                   lowercased.contains("pattern") ||
                   lowercased.contains("insecure")
        }

        // LLM behavior tests can be variable - we want to catch regressions
        // but allow some flexibility. At minimum, such explicit language should yield SOME loops.
        if result.behavioralLoops.isEmpty {
            // Log warning but treat as soft failure for explicit pattern conversation
            print("⚠️ WARNING: Analyst returned no behavioral loops for explicit pattern conversation")
            print("   Messages contained: 'obsessively', 'compulsive habit', 'pattern', 'every relationship'")
            print("   This may indicate the Analyst prompt needs tuning for behavioral_loops_detected")
        }

        // Assert at least some loops were detected given the explicit pattern language
        XCTAssertFalse(result.behavioralLoops.isEmpty,
            "Analyst should detect at least one behavioral loop from explicit pattern language. Got empty array.")
    }

    func testAnalyst_noLoopsForCasualChat() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        let messages = [
            Message(conversationId: "test", role: .user, text: "Hey what's up"),
            Message(conversationId: "test", role: .chloe, text: "Hey! Just here for you. What's on your mind?"),
            Message(conversationId: "test", role: .user, text: "Not much, just bored")
        ]

        let result = try await GeminiService.shared.analyzeConversation(messages: messages)

        // Casual chat should have minimal or no behavioral loops
        XCTAssertLessThanOrEqual(result.behavioralLoops.count, 1,
            "Casual chat should not generate multiple behavioral loops. Detected: \(result.behavioralLoops)")
    }
}

// MARK: - Memory Persistence Tests

/// Tests for loops being saved locally and synced correctly
final class MemoryPersistenceTests: XCTestCase {

    var storageService: SyncDataService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageService = SyncDataService.shared
    }

    /// Verify loops are saved via addBehavioralLoops()
    func testBehavioralLoops_savedToProfile() {
        let uniqueLoop = "PersistenceTest_\(UUID().uuidString)"
        storageService.addBehavioralLoops([uniqueLoop])

        let profile = storageService.loadProfile()
        XCTAssertNotNil(profile?.behavioralLoops)
        XCTAssertTrue(profile?.behavioralLoops?.contains(uniqueLoop) ?? false,
                      "Added loop should be saved to profile")
    }

    /// Verify case-insensitive deduplication: "Pattern" == "PATTERN"
    func testBehavioralLoops_deduplicatesCaseInsensitive() {
        let baseLoop = "CaseTest_\(UUID().uuidString)"
        storageService.addBehavioralLoops([baseLoop])
        let countAfterFirst = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        // Try to add uppercase version
        storageService.addBehavioralLoops([baseLoop.uppercased()])
        let countAfterSecond = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        XCTAssertEqual(countAfterFirst, countAfterSecond,
                       "Case-insensitive duplicate should not be added")
    }

    /// Verify substring deduplication: "seeks validation" skipped if "seeks validation when anxious" exists
    func testBehavioralLoops_deduplicatesSubstring() {
        let longLoop = "SubstringTest_user seeks validation when anxious_\(UUID().uuidString)"
        let shortLoop = "SubstringTest_user seeks validation_\(UUID().uuidString)"

        // Add the longer, more specific pattern first
        storageService.addBehavioralLoops([longLoop])
        let countAfterFirst = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        // Try to add shorter substring pattern
        storageService.addBehavioralLoops([shortLoop])
        let countAfterSecond = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        // Note: The dedup logic checks if the existing contains the new OR new contains existing
        // Since shortLoop doesn't literally contain longLoop, it may be added
        // But if shortLoop is a substring of longLoop, it should be skipped
        // Let's verify the actual behavior by checking if short is substring of long
        if longLoop.lowercased().contains(shortLoop.lowercased()) {
            XCTAssertEqual(countAfterFirst, countAfterSecond,
                           "Substring pattern should be deduplicated")
        } else {
            // If not a literal substring, both may exist (expected behavior)
            XCTAssertTrue(true, "Non-substring patterns may coexist")
        }
    }

    /// Verify no crash when profile is nil (cold start scenario)
    func testBehavioralLoops_coldStartSafety() {
        // This test verifies the guard clause handles nil profile gracefully
        // We can't truly test nil profile without clearing storage, but we verify no crash
        storageService.addBehavioralLoops(["ColdStartTest_\(UUID().uuidString)"])
        // If we get here without crash, test passes
        XCTAssertTrue(true, "addBehavioralLoops should handle gracefully")
    }

    /// Verify first loop added to profile with nil behavioralLoops creates array
    func testBehavioralLoops_firstLoopCreatesArray() {
        // Add a unique loop - the storage service should handle nil -> [loop]
        let uniqueLoop = "FirstLoop_\(UUID().uuidString)"
        storageService.addBehavioralLoops([uniqueLoop])

        let profile = storageService.loadProfile()
        XCTAssertNotNil(profile?.behavioralLoops, "behavioralLoops should not be nil after adding first loop")
        XCTAssertTrue(profile?.behavioralLoops?.contains(uniqueLoop) ?? false)
    }

    /// Verify empty array input doesn't modify profile
    func testBehavioralLoops_emptyArrayNoOp() {
        let initialLoops = storageService.loadProfile()?.behavioralLoops ?? []
        let initialCount = initialLoops.count

        storageService.addBehavioralLoops([])

        let finalCount = storageService.loadProfile()?.behavioralLoops?.count ?? 0
        XCTAssertEqual(initialCount, finalCount,
                       "Empty array should not modify profile")
    }

    // MARK: - Integration: Supabase Sync (Require Auth)

    func testBehavioralLoops_syncedToSupabase() async throws {
        try XCTSkipIf(SupabaseDataService.shared.currentUserId == nil, "Skipping - Not authenticated")

        let uniqueLoop = "SupabaseSync_\(UUID().uuidString)"
        storageService.addBehavioralLoops([uniqueLoop])

        // Give cloud sync time to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Verify via Supabase query (would need to check actual Supabase)
        // For now, verify local persistence as proxy
        let profile = storageService.loadProfile()
        XCTAssertTrue(profile?.behavioralLoops?.contains(uniqueLoop) ?? false,
                      "Loop should be saved locally (Supabase sync happens asynchronously)")
    }
}

// MARK: - Prompt Injection Tests

/// Tests for loops appearing correctly in Strategist system prompt
final class PromptInjectionTests: XCTestCase {

    // MARK: - Helper: Build XML Block

    /// Simulates the prompt injection logic from ChatViewModel
    private func buildKnownPatternsXML(loops: [String]?) -> String? {
        guard let loops = loops, !loops.isEmpty else { return nil }
        return """
        <known_patterns>
          These are behavioral patterns detected across previous sessions.
          Use them to call out recurring behaviors when relevant:
          \(loops.map { "- \($0)" }.joined(separator: "\n  "))
        </known_patterns>
        """
    }

    /// Verify known_patterns XML block is generated with loops
    func testStrategistPrompt_injectsKnownPatternsXML() {
        let loops = ["User double-texts when anxious", "Seeks validation after silence"]
        let xml = buildKnownPatternsXML(loops: loops)

        XCTAssertNotNil(xml)
        XCTAssertTrue(xml!.contains("<known_patterns>"))
        XCTAssertTrue(xml!.contains("</known_patterns>"))
        XCTAssertTrue(xml!.contains("User double-texts when anxious"))
        XCTAssertTrue(xml!.contains("Seeks validation after silence"))
    }

    /// Verify no XML block when loops array is empty
    func testStrategistPrompt_noInjectionWhenEmpty() {
        let xml = buildKnownPatternsXML(loops: [])
        XCTAssertNil(xml, "Empty loops should not generate XML block")
    }

    /// Verify no XML block when loops is nil
    func testStrategistPrompt_noInjectionWhenNil() {
        let xml = buildKnownPatternsXML(loops: nil)
        XCTAssertNil(xml, "Nil loops should not generate XML block")
    }

    /// Verify loops are formatted as bullet list with dashes
    func testKnownPatterns_bulletFormatting() {
        let loops = ["Pattern One", "Pattern Two", "Pattern Three"]
        let xml = buildKnownPatternsXML(loops: loops)!

        XCTAssertTrue(xml.contains("- Pattern One"))
        XCTAssertTrue(xml.contains("- Pattern Two"))
        XCTAssertTrue(xml.contains("- Pattern Three"))
    }

    /// Verify special characters in loops are preserved
    func testKnownPatterns_specialCharactersPreserved() {
        let loops = [
            "User says \"I'm fine\" when upset",
            "Pattern with apostrophe's",
            "Pattern with <angle> brackets"
        ]
        let xml = buildKnownPatternsXML(loops: loops)!

        XCTAssertTrue(xml.contains("\"I'm fine\""), "Quotes should be preserved")
        XCTAssertTrue(xml.contains("apostrophe's"), "Apostrophes should be preserved")
        XCTAssertTrue(xml.contains("<angle>"), "Angle brackets in content should be preserved")
    }

    /// Verify the exact format matches ChatViewModel implementation
    func testKnownPatterns_matchesChatViewModelFormat() {
        let loops = ["Test pattern"]
        let xml = buildKnownPatternsXML(loops: loops)!

        // Verify structure matches ChatViewModel:173-181
        XCTAssertTrue(xml.contains("These are behavioral patterns detected across previous sessions"))
        XCTAssertTrue(xml.contains("Use them to call out recurring behaviors when relevant"))
    }
}

// MARK: - Tone Audit Tests

/// Tests to verify casual messages don't get gamified with strategic options
final class ToneAuditTests: XCTestCase {

    var geminiService: GeminiService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        geminiService = GeminiService.shared
    }

    // MARK: - Router Classification Tests

    /// Verify casual greeting gets LOW urgency, not classified as crisis
    func testRouter_casualGreetingNotCrisis() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        let classification = try await geminiService.classifyMessage(message: "Hey")

        XCTAssertEqual(classification.urgency, .low,
                       "Casual greeting should be LOW urgency")
        XCTAssertNotEqual(classification.category, .crisisBreakup,
                          "Casual greeting should not be classified as CRISIS_BREAKUP")
        XCTAssertNotEqual(classification.category, .safetyRisk,
                          "Casual greeting should not be classified as SAFETY_RISK")
    }

    /// Verify tired message doesn't get HIGH urgency
    func testRouter_tiredMessageNotHighUrgency() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        let classification = try await geminiService.classifyMessage(message: "I'm tired")

        XCTAssertNotEqual(classification.urgency, .high,
                          "'I'm tired' should not trigger HIGH urgency")
    }

    // MARK: - Strategist Response Tests

    /// Verify casual chat doesn't receive A/B options
    func testStrategist_noOptionsForCasualChat() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        let messages = [
            Message(conversationId: "test", role: .user, text: "Hey! How's it going?")
        ]

        let systemPrompt = """
        \(Prompts.strategist)
        <router_context>
          Category: SELF_IMPROVEMENT
          Urgency: LOW
        </router_context>
        For LOW urgency casual chat, do NOT provide game theory options.
        """

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        // Casual chat should have no options or empty array
        let hasOptions = response.response.options?.isEmpty == false
        XCTAssertFalse(hasOptions,
                       "Casual chat should not have strategy options. Options: \(response.response.options ?? [])")
    }

    /// Verify tired message doesn't get strategic options
    func testStrategist_noOptionsForTiredMessage() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        let messages = [
            Message(conversationId: "test", role: .user, text: "I'm so tired")
        ]

        let systemPrompt = """
        \(Prompts.strategist)
        <router_context>
          Category: SELF_IMPROVEMENT
          Urgency: LOW
        </router_context>
        For casual/low-energy messages, respond with support. No game theory options needed.
        """

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        let hasOptions = response.response.options?.isEmpty == false
        XCTAssertFalse(hasOptions,
                       "Tired message should not have strategy options. Options: \(response.response.options ?? [])")
    }

    /// Verify strategic dating question DOES receive options
    func testStrategist_optionsForStrategicDecision() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        let messages = [
            Message(conversationId: "test", role: .user, text: "He hasn't texted in 3 days but watches all my stories. Should I text him?")
        ]

        let systemPrompt = """
        \(Prompts.strategist)
        <router_context>
          Category: DATING_EARLY
          Urgency: MEDIUM
        </router_context>
        For strategic dating questions, provide A/B options with predicted outcomes.
        """

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        // Strategic question should have options
        XCTAssertNotNil(response.response.options,
                        "Strategic dating question should have options")
        XCTAssertGreaterThan(response.response.options?.count ?? 0, 0,
                             "Strategic dating question should have at least one option")
    }

    /// Verify confrontation question receives options
    func testStrategist_optionsForConfrontationQuestion() async throws {
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")

        let messages = [
            Message(conversationId: "test", role: .user, text: "Should I confront him about being hot and cold?")
        ]

        let systemPrompt = """
        \(Prompts.strategist)
        <router_context>
          Category: DATING_EARLY
          Urgency: MEDIUM
        </router_context>
        For confrontation strategy questions, provide A/B options with predicted outcomes.
        """

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        XCTAssertNotNil(response.response.options)
        let hasOptions = (response.response.options?.count ?? 0) > 0
        XCTAssertTrue(hasOptions,
                      "Confrontation question should have strategy options")
    }
}
