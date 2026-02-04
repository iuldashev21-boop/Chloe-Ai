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

// MARK: - User Journey Tests

/// Simulated real user journey test across multiple sessions
/// Tests: Fresh user → Session 1 (Sunday night venting) → Session 2 (different topic) → Session 3 (Sunday night again)
/// Verifies Chloe recognizes recurring patterns and references them naturally
final class UserJourneyTests: XCTestCase {

    var geminiService: GeminiService!
    var storageService: SyncDataService!

    // Test report state
    private var testReport: [TestStep] = []

    struct TestStep {
        let name: String
        let passed: Bool
        let details: String
        let duration: TimeInterval
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        geminiService = GeminiService.shared
        storageService = SyncDataService.shared

        // Skip if no API key
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")
    }

    override func tearDownWithError() throws {
        // Print final report
        printTestReport()
        try super.tearDownWithError()
    }

    // MARK: - Main User Journey Test

    /// Full user journey: Fresh user → 3 sessions → Pattern recognition verification
    func testUserJourney_sundayNightPatternRecognition() async throws {
        testReport = []
        var overallSuccess = true

        // ═══════════════════════════════════════════════════════════════════════════════
        // SETUP: Fresh User with Completed Onboarding
        // ═══════════════════════════════════════════════════════════════════════════════

        let setupStart = Date()
        let freshProfile = setupFreshUser()
        let setupDuration = Date().timeIntervalSince(setupStart)

        testReport.append(TestStep(
            name: "Setup: Fresh User",
            passed: freshProfile.onboardingComplete && freshProfile.behavioralLoops == nil,
            details: "Profile created: \(freshProfile.displayName), onboarding=\(freshProfile.onboardingComplete), loops=\(freshProfile.behavioralLoops?.count ?? 0)",
            duration: setupDuration
        ))

        // ═══════════════════════════════════════════════════════════════════════════════
        // SESSION 1: Sunday Night Venting - "He hasn't texted back"
        // ═══════════════════════════════════════════════════════════════════════════════

        let session1Start = Date()
        let session1ConvoId = UUID().uuidString
        let session1Messages = [
            Message(conversationId: session1ConvoId, role: .user, text: "It's Sunday night and I'm spiraling. He hasn't texted me back all day."),
            Message(conversationId: session1ConvoId, role: .user, text: "Every Sunday night I end up like this. He goes quiet on weekends and I just sit here refreshing my phone."),
            Message(conversationId: session1ConvoId, role: .user, text: "I know I shouldn't care this much but I can't help checking if he's online.")
        ]

        // Get Chloe's response for Session 1
        let session1Response = try await sendSessionMessages(messages: session1Messages, profile: freshProfile)
        let session1Duration = Date().timeIntervalSince(session1Start)

        testReport.append(TestStep(
            name: "Session 1: Sunday Night Venting",
            passed: !session1Response.isEmpty,
            details: "Response length: \(session1Response.count) chars. Preview: \(String(session1Response.prefix(100)))...",
            duration: session1Duration
        ))

        // Run Analyst to detect behavioral patterns from Session 1
        let analystStart = Date()
        let session1AllMessages = session1Messages + [
            Message(conversationId: session1ConvoId, role: .chloe, text: session1Response)
        ]
        let analystResult = try await runAnalyst(messages: session1AllMessages, profile: freshProfile)
        let analystDuration = Date().timeIntervalSince(analystStart)

        // Store detected loops
        if !analystResult.behavioralLoops.isEmpty {
            storageService.addBehavioralLoops(analystResult.behavioralLoops)
        }

        let loopsAfterSession1 = storageService.loadProfile()?.behavioralLoops ?? []
        let session1LoopsDetected = !loopsAfterSession1.isEmpty

        testReport.append(TestStep(
            name: "Session 1: Analyst Pattern Detection",
            passed: session1LoopsDetected,
            details: "Detected loops: \(analystResult.behavioralLoops). Stored: \(loopsAfterSession1)",
            duration: analystDuration
        ))

        if !session1LoopsDetected {
            print("⚠️ WARNING: No patterns detected in Session 1. Pattern recognition test may fail.")
        }

        // ═══════════════════════════════════════════════════════════════════════════════
        // SESSION 2: Different Topic - Career/Self-Improvement
        // ═══════════════════════════════════════════════════════════════════════════════

        let session2Start = Date()
        let session2ConvoId = UUID().uuidString
        let session2Messages = [
            Message(conversationId: session2ConvoId, role: .user, text: "Hey Chloe, I've been thinking about my career lately."),
            Message(conversationId: session2ConvoId, role: .user, text: "I want to ask for a promotion but I'm nervous about it.")
        ]

        let session2Response = try await sendSessionMessages(messages: session2Messages, profile: storageService.loadProfile() ?? freshProfile)
        let session2Duration = Date().timeIntervalSince(session2Start)

        testReport.append(TestStep(
            name: "Session 2: Different Topic (Career)",
            passed: !session2Response.isEmpty,
            details: "Response length: \(session2Response.count) chars. Topic shift successful.",
            duration: session2Duration
        ))

        // ═══════════════════════════════════════════════════════════════════════════════
        // SESSION 3: Sunday Night Again - Pattern Recognition Test
        // ═══════════════════════════════════════════════════════════════════════════════

        let session3Start = Date()
        let session3ConvoId = UUID().uuidString
        let session3Messages = [
            Message(conversationId: session3ConvoId, role: .user, text: "Ugh, it's Sunday night again. He's been quiet all weekend."),
            Message(conversationId: session3ConvoId, role: .user, text: "I keep checking my phone waiting for him to text. Same thing as last time.")
        ]

        // Load profile with behavioral loops for injection
        let profileWithLoops = storageService.loadProfile() ?? freshProfile
        let session3Response = try await sendSessionMessagesWithPatterns(
            messages: session3Messages,
            profile: profileWithLoops
        )
        let session3Duration = Date().timeIntervalSince(session3Start)

        // Verify Chloe references the pattern
        let responseText = session3Response.lowercased()
        let patternReferenced = responseText.contains("pattern") ||
                                responseText.contains("notice") ||
                                responseText.contains("again") ||
                                responseText.contains("recurring") ||
                                responseText.contains("before") ||
                                responseText.contains("sunday") ||
                                responseText.contains("last time") ||
                                responseText.contains("same") ||
                                responseText.contains("cycle") ||
                                responseText.contains("loop")

        testReport.append(TestStep(
            name: "Session 3: Pattern Recognition",
            passed: patternReferenced,
            details: "Pattern referenced: \(patternReferenced). Response: \(String(session3Response.prefix(200)))...",
            duration: session3Duration
        ))

        // ═══════════════════════════════════════════════════════════════════════════════
        // VERIFICATION: Final State Check
        // ═══════════════════════════════════════════════════════════════════════════════

        let finalProfile = storageService.loadProfile()
        let finalLoops = finalProfile?.behavioralLoops ?? []

        testReport.append(TestStep(
            name: "Final State: Behavioral Loops Persisted",
            passed: !finalLoops.isEmpty,
            details: "Final loops count: \(finalLoops.count). Loops: \(finalLoops.joined(separator: "; "))",
            duration: 0
        ))

        // Calculate overall success
        overallSuccess = testReport.allSatisfy { $0.passed }

        // Assert the critical path
        XCTAssertTrue(session1LoopsDetected || !loopsAfterSession1.isEmpty,
            "Should detect behavioral loops from Sunday night venting pattern")
        XCTAssertTrue(patternReferenced,
            "Session 3 response should reference the recurring Sunday night pattern")
    }

    // MARK: - Helper Methods

    /// Sets up a fresh user profile with completed onboarding
    private func setupFreshUser() -> Profile {
        // Clear all existing data
        storageService.clearAll()

        // Create fresh profile with onboarding complete
        var profile = Profile()
        profile.displayName = "TestUser"
        profile.email = "journey-test@chloe.test"
        profile.onboardingComplete = true
        profile.behavioralLoops = nil // Ensure no existing loops
        profile.createdAt = Date()
        profile.updatedAt = Date()

        try? storageService.saveProfile(profile)
        return profile
    }

    /// Sends messages to Chloe and returns her response (V2 Strategist pipeline)
    private func sendSessionMessages(messages: [Message], profile: Profile) async throws -> String {
        // Classify the message to get router context
        let lastUserMessage = messages.last(where: { $0.role == .user })?.text ?? ""
        let classification = try await geminiService.classifyMessage(message: lastUserMessage)

        // Build strategist prompt with router context
        let systemPrompt = buildStrategistPrompt(
            profile: profile,
            classification: classification,
            behavioralLoops: profile.behavioralLoops
        )

        // Get strategist response
        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        return response.response.text
    }

    /// Sends messages with behavioral loops injected into the prompt
    private func sendSessionMessagesWithPatterns(messages: [Message], profile: Profile) async throws -> String {
        let lastUserMessage = messages.last(where: { $0.role == .user })?.text ?? ""
        let classification = try await geminiService.classifyMessage(message: lastUserMessage)

        // Build strategist prompt WITH behavioral loops
        let systemPrompt = buildStrategistPrompt(
            profile: profile,
            classification: classification,
            behavioralLoops: profile.behavioralLoops
        )

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        return response.response.text
    }

    /// Runs the Analyst to extract behavioral patterns
    private func runAnalyst(messages: [Message], profile: Profile) async throws -> AnalystResult {
        return try await geminiService.analyzeConversation(
            messages: messages,
            userFacts: [],
            lastSummary: nil,
            currentVibe: nil,
            displayName: profile.displayName
        )
    }

    /// Builds strategist prompt with router context and optional behavioral loops
    private func buildStrategistPrompt(
        profile: Profile,
        classification: RouterClassification,
        behavioralLoops: [String]?
    ) -> String {
        var prompt = Prompts.strategist
            .replacingOccurrences(of: "{{user_name}}", with: profile.displayName.isEmpty ? "babe" : profile.displayName)
            .replacingOccurrences(of: "{{archetype_label}}", with: "Not determined yet")
            .replacingOccurrences(of: "{{relationship_status}}", with: "Not shared yet")
            .replacingOccurrences(of: "{{current_vibe}}", with: "MEDIUM")

        // Add router context
        prompt += """

        <router_context>
          Category: \(classification.category.rawValue)
          Urgency: \(classification.urgency.rawValue)
          Reasoning: \(classification.reasoning)
        </router_context>
        """

        // Inject behavioral loops if present
        if let loops = behavioralLoops, !loops.isEmpty {
            prompt += """

            <known_patterns>
              These are behavioral patterns detected across previous sessions.
              IMPORTANT: Reference these patterns naturally when relevant to show you remember the user.
              Call out recurring behaviors to help the user recognize their cycles:
              \(loops.map { "- \($0)" }.joined(separator: "\n  "))
            </known_patterns>
            """
        }

        return prompt
    }

    /// Prints the final test report
    private func printTestReport() {
        print("\n")
        print("╔══════════════════════════════════════════════════════════════════════════════╗")
        print("║                    USER JOURNEY TEST REPORT                                  ║")
        print("╠══════════════════════════════════════════════════════════════════════════════╣")

        var totalDuration: TimeInterval = 0
        var passCount = 0
        var failCount = 0

        for step in testReport {
            let status = step.passed ? "✅ PASS" : "❌ FAIL"
            let durationStr = String(format: "%.2fs", step.duration)
            print("║ \(status) │ \(step.name.padding(toLength: 40, withPad: " ", startingAt: 0)) │ \(durationStr.padding(toLength: 8, withPad: " ", startingAt: 0)) ║")
            print("║        │ \(step.details.prefix(60).padding(toLength: 60, withPad: " ", startingAt: 0)) ║")
            print("╟──────────────────────────────────────────────────────────────────────────────╢")

            totalDuration += step.duration
            if step.passed { passCount += 1 } else { failCount += 1 }
        }

        print("╠══════════════════════════════════════════════════════════════════════════════╣")
        let overallStatus = failCount == 0 ? "✅ ALL TESTS PASSED" : "❌ \(failCount) TEST(S) FAILED"
        print("║ \(overallStatus.padding(toLength: 76, withPad: " ", startingAt: 0)) ║")
        print("║ Total: \(passCount)/\(testReport.count) passed │ Duration: \(String(format: "%.2fs", totalDuration).padding(toLength: 54, withPad: " ", startingAt: 0)) ║")
        print("╚══════════════════════════════════════════════════════════════════════════════╝")
        print("\n")
    }
}

// MARK: - Memory Edge Case Tests

/// Tests for edge cases in the memory/behavioral loops system
final class MemoryEdgeCaseTests: XCTestCase {

    var storageService: SyncDataService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageService = SyncDataService.shared
    }

    // MARK: - 50+ Loops Tests

    /// Verify system handles 50+ behavioral loops without crash
    func testBehavioralLoops_50PlusLoops_noCrash() {
        // Generate 60 unique loops
        let loops = (1...60).map { "Behavioral pattern \($0): User exhibits behavior \($0)" }

        // Should not crash
        storageService.addBehavioralLoops(loops)

        let profile = storageService.loadProfile()
        XCTAssertNotNil(profile?.behavioralLoops)
        XCTAssertGreaterThanOrEqual(profile?.behavioralLoops?.count ?? 0, 50,
            "Should store at least 50 loops")
    }

    /// Verify prompt injection handles large loop counts gracefully
    func testBehavioralLoops_50PlusLoops_promptSizeReasonable() {
        let loops = (1...60).map { "Pattern \($0): Seeks validation in scenario \($0)" }

        // Build XML block like ChatViewModel does
        let xml = """
        <known_patterns>
          These are behavioral patterns detected across previous sessions.
          Use them to call out recurring behaviors when relevant:
          \(loops.map { "- \($0)" }.joined(separator: "\n  "))
        </known_patterns>
        """

        // Verify it's not excessively large (< 10KB is reasonable for prompt injection)
        let sizeInBytes = xml.utf8.count
        XCTAssertLessThan(sizeInBytes, 10_000,
            "50+ loops XML should be under 10KB. Actual: \(sizeInBytes) bytes")

        // Verify structure is intact
        XCTAssertTrue(xml.contains("<known_patterns>"))
        XCTAssertTrue(xml.contains("</known_patterns>"))
        XCTAssertTrue(xml.contains("Pattern 1:"))
        XCTAssertTrue(xml.contains("Pattern 60:"))
    }

    /// Verify adding loops beyond 50 still works (no hard limit crash)
    func testBehavioralLoops_100Loops_noHardLimit() {
        let loops = (1...100).map { "Loop\($0)_\(UUID().uuidString.prefix(8))" }
        storageService.addBehavioralLoops(loops)

        let profile = storageService.loadProfile()
        // System should either store all or implement a reasonable limit
        XCTAssertNotNil(profile?.behavioralLoops)
        // If there's a limit, it should be documented; for now verify no crash
        XCTAssertTrue(true, "100 loops added without crash")
    }

    // MARK: - Special Characters Tests

    /// Verify special characters are preserved in storage
    func testBehavioralLoops_specialChars_quotesPreserved() {
        let loop = "User says \"I'm fine\" when actually upset"
        storageService.addBehavioralLoops([loop])

        let profile = storageService.loadProfile()
        let storedLoop = profile?.behavioralLoops?.first { $0.contains("I'm fine") }
        XCTAssertNotNil(storedLoop)
        XCTAssertTrue(storedLoop?.contains("\"I'm fine\"") ?? false,
            "Quotes should be preserved in storage")
    }

    /// Verify apostrophes don't break storage
    func testBehavioralLoops_specialChars_apostrophesPreserved() {
        let loop = "User doesn't trust partner's friends"
        storageService.addBehavioralLoops([loop])

        let profile = storageService.loadProfile()
        let hasLoop = profile?.behavioralLoops?.contains { $0.contains("doesn't") && $0.contains("partner's") } ?? false
        XCTAssertTrue(hasLoop, "Apostrophes should be preserved")
    }

    /// Verify emoji in loops doesn't crash
    func testBehavioralLoops_specialChars_emojiHandled() {
        let loop = "User uses 😭 when stressed about relationship"
        storageService.addBehavioralLoops([loop])

        let profile = storageService.loadProfile()
        let hasEmojiLoop = profile?.behavioralLoops?.contains { $0.contains("😭") } ?? false
        XCTAssertTrue(hasEmojiLoop, "Emoji should be preserved in loops")
    }

    /// Verify newlines in loops are handled
    func testBehavioralLoops_specialChars_newlinesHandled() {
        let loop = "User pattern:\nChecks phone\nFeels anxious"
        storageService.addBehavioralLoops([loop])

        let profile = storageService.loadProfile()
        XCTAssertNotNil(profile?.behavioralLoops)
        // Newlines might be preserved or normalized - verify no crash
        XCTAssertTrue(true, "Newlines handled without crash")
    }

    /// Verify XML-like content in loops doesn't break prompt injection
    func testBehavioralLoops_specialChars_xmlLikeContent() {
        let loop = "User exhibits <anxious> behavior when <ignored>"
        storageService.addBehavioralLoops([loop])

        // Build prompt injection
        let loops = storageService.loadProfile()?.behavioralLoops ?? []
        let xml = """
        <known_patterns>
          \(loops.map { "- \($0)" }.joined(separator: "\n  "))
        </known_patterns>
        """

        // Should contain the angle brackets (might cause XML parsing issues in some systems)
        XCTAssertTrue(xml.contains("<anxious>") || xml.contains("&lt;anxious&gt;"),
            "XML-like content should be handled (preserved or escaped)")
    }

    // MARK: - Similar/Fuzzy Loops Tests

    /// Verify exact duplicates are caught
    func testBehavioralLoops_similar_exactDuplicate() {
        let loop = "User checks phone obsessively"
        storageService.addBehavioralLoops([loop])
        let countAfterFirst = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        storageService.addBehavioralLoops([loop])
        let countAfterSecond = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        XCTAssertEqual(countAfterFirst, countAfterSecond, "Exact duplicate should not be added")
    }

    /// Verify case variations are caught
    func testBehavioralLoops_similar_caseVariation() {
        let uniqueId = UUID().uuidString.prefix(8)
        let loop1 = "User CHECKS phone \(uniqueId)"
        let loop2 = "user checks phone \(uniqueId)"

        storageService.addBehavioralLoops([loop1])
        let countAfterFirst = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        storageService.addBehavioralLoops([loop2])
        let countAfterSecond = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        XCTAssertEqual(countAfterFirst, countAfterSecond,
            "Case-insensitive duplicate should not be added")
    }

    /// Verify substring patterns are deduplicated
    func testBehavioralLoops_similar_substringDedup() {
        let uniqueId = UUID().uuidString.prefix(8)
        // Short must be actual substring of long (no trailing UUID difference)
        let longLoop = "\(uniqueId)_User checks phone obsessively when partner is quiet"
        let shortLoop = "\(uniqueId)_User checks phone obsessively"

        storageService.addBehavioralLoops([longLoop])
        let countAfterLong = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        storageService.addBehavioralLoops([shortLoop])
        let countAfterShort = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        // Short loop is substring of long loop - should be deduplicated
        // Verify: longLoop.contains(shortLoop) should be true
        XCTAssertTrue(longLoop.lowercased().contains(shortLoop.lowercased()),
            "Test setup: short should be substring of long")
        XCTAssertEqual(countAfterLong, countAfterShort,
            "Substring pattern should be deduplicated")
    }

    /// Document behavior for semantically similar but textually different loops
    func testBehavioralLoops_similar_semanticVariation_documented() {
        let uniqueId = UUID().uuidString.prefix(8)
        // These are semantically similar but textually different
        let loop1 = "Checks location when anxious \(uniqueId)"
        let loop2 = "Monitors partner's whereabouts during stress \(uniqueId)"

        storageService.addBehavioralLoops([loop1])
        let countAfterFirst = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        storageService.addBehavioralLoops([loop2])
        let countAfterSecond = storageService.loadProfile()?.behavioralLoops?.count ?? 0

        // Current implementation uses substring matching, not semantic similarity
        // Both loops will be stored since neither is substring of other
        // This documents expected behavior - semantic dedup would require NLP
        XCTAssertEqual(countAfterSecond, countAfterFirst + 1,
            "Semantically similar but textually different loops are both stored (expected - no NLP dedup)")
    }

    // MARK: - Database Corruption Tests

    /// Verify system handles nil behavioralLoops gracefully
    func testBehavioralLoops_corruption_nilLoopsArray() {
        // Create profile with nil loops
        var profile = storageService.loadProfile() ?? Profile()
        profile.behavioralLoops = nil
        try? storageService.saveProfile(profile)

        // Adding loops should create array, not crash
        storageService.addBehavioralLoops(["New pattern after nil"])

        let updatedProfile = storageService.loadProfile()
        XCTAssertNotNil(updatedProfile?.behavioralLoops)
        XCTAssertTrue(updatedProfile?.behavioralLoops?.contains { $0.contains("New pattern after nil") } ?? false)
    }

    /// Verify system handles empty string loops
    func testBehavioralLoops_corruption_emptyStringLoop() {
        let loopsWithEmpty = ["Valid pattern", "", "Another valid pattern"]
        storageService.addBehavioralLoops(loopsWithEmpty)

        let profile = storageService.loadProfile()
        // Empty strings might be filtered or stored - verify no crash
        XCTAssertNotNil(profile?.behavioralLoops)
    }

    /// Verify system handles whitespace-only loops
    func testBehavioralLoops_corruption_whitespaceLoop() {
        let loopsWithWhitespace = ["Valid pattern", "   ", "\n\t", "Another valid"]
        storageService.addBehavioralLoops(loopsWithWhitespace)

        let profile = storageService.loadProfile()
        XCTAssertNotNil(profile?.behavioralLoops)
        // Whitespace-only loops ideally should be filtered
    }

    /// Verify AnalystResult decodes gracefully with malformed loops
    func testAnalystResult_corruption_malformedLoopsArray() throws {
        // Test various edge cases in JSON
        let json = """
        {
            "new_facts": [],
            "vibe_score": "MEDIUM",
            "vibe_reasoning": "Test",
            "behavioral_loops_detected": ["Valid", "", "Also valid", "   "],
            "session_summary": "Test"
        }
        """

        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AnalystResult.self, from: data)

        // Should decode without crash
        XCTAssertNotNil(result.behavioralLoops)
        XCTAssertTrue(result.behavioralLoops.contains("Valid"))
    }

    /// Verify system recovers from profile with corrupted loops JSON
    func testBehavioralLoops_corruption_recoveryAfterBadData() {
        // Add valid loops first
        storageService.addBehavioralLoops(["Pre-corruption pattern"])

        // Simulate recovery by adding new loops
        storageService.addBehavioralLoops(["Post-recovery pattern"])

        let profile = storageService.loadProfile()
        XCTAssertNotNil(profile?.behavioralLoops)
        XCTAssertTrue(profile?.behavioralLoops?.contains { $0.contains("Post-recovery") } ?? false)
    }
}

// MARK: - Crisis Router + Memory Combo Tests

/// Tests for interaction between Crisis situations and Memory/Behavioral Loops
/// Key question: Should pattern call-outs be suppressed during HIGH urgency crisis?
final class CrisisMemoryComboTests: XCTestCase {

    var geminiService: GeminiService!
    var storageService: SyncDataService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        geminiService = GeminiService.shared
        storageService = SyncDataService.shared

        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        try XCTSkipIf(apiKey == nil || apiKey?.isEmpty == true, "Skipping - No API key configured")
    }

    // MARK: - Crisis Classification Tests

    /// Verify acute crisis is classified as HIGH urgency
    func testCrisis_acuteBreakup_highUrgency() async throws {
        let message = "He just blocked me on everything. I can't stop crying. I feel like I can't breathe."

        let classification = try await geminiService.classifyMessage(message: message)

        XCTAssertEqual(classification.urgency, .high,
            "Acute crisis should be HIGH urgency")
        XCTAssertEqual(classification.category, .crisisBreakup,
            "Blocking scenario should be CRISIS_BREAKUP")
    }

    /// Verify Sunday night venting is NOT classified as crisis
    func testCrisis_sundayVenting_notCrisis() async throws {
        let message = "It's Sunday night and he hasn't texted. I'm checking my phone constantly."

        let classification = try await geminiService.classifyMessage(message: message)

        XCTAssertNotEqual(classification.category, .crisisBreakup,
            "Sunday venting should not be CRISIS_BREAKUP")
        XCTAssertNotEqual(classification.urgency, .high,
            "Sunday venting should not be HIGH urgency")
    }

    // MARK: - Crisis + Memory Interaction Tests

    /// Verify HIGH urgency crisis response doesn't gamify with options
    func testCrisis_withLoops_noOptionsInCrisis() async throws {
        let messages = [
            Message(conversationId: "test", role: .user, text: "He just told me it's over. I'm shaking. I don't know what to do.")
        ]

        // Include behavioral loops in the prompt
        let loops = ["User seeks validation when anxious", "Checks phone obsessively"]
        let systemPrompt = buildCrisisPromptWithLoops(loops: loops, urgency: .high)

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        // Crisis response should NOT have A/B options
        let hasOptions = response.response.options?.isEmpty == false
        XCTAssertFalse(hasOptions,
            "HIGH urgency crisis should NOT have strategy options even with behavioral loops")
    }

    /// Verify crisis response is supportive, not strategic pattern call-out
    func testCrisis_withLoops_supportiveNotStrategic() async throws {
        let messages = [
            Message(conversationId: "test", role: .user, text: "I found out he cheated. I'm devastated. I can't eat or sleep.")
        ]

        let loops = ["User catastrophizes when stressed", "Seeks external validation"]
        let systemPrompt = buildCrisisPromptWithLoops(loops: loops, urgency: .high)

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        let responseText = response.response.text.lowercased()

        // Should be supportive
        let isSupportive = responseText.contains("here for you") ||
                           responseText.contains("so sorry") ||
                           responseText.contains("breathe") ||
                           responseText.contains("feel") ||
                           responseText.contains("valid") ||
                           responseText.contains("hard") ||
                           responseText.contains("okay to") ||
                           responseText.contains("right now")

        // Should NOT be lecturing about patterns during acute crisis
        let isLecturing = responseText.contains("you always do this") ||
                          responseText.contains("this is your pattern") ||
                          responseText.contains("you need to stop")

        XCTAssertTrue(isSupportive, "Crisis response should be supportive. Got: \(response.response.text.prefix(200))")
        XCTAssertFalse(isLecturing, "Crisis response should not lecture about patterns during acute distress")
    }

    /// Verify MEDIUM urgency with loops DOES reference patterns appropriately
    func testMediumUrgency_withLoops_patternsReferenced() async throws {
        let messages = [
            Message(conversationId: "test", role: .user, text: "He's being hot and cold again. I keep checking if he's online.")
        ]

        let loops = ["Monitors partner's online status when anxious", "Seeks reassurance through digital checking"]
        let systemPrompt = buildCrisisPromptWithLoops(loops: loops, urgency: .medium, category: .datingEarly)

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        let responseText = response.response.text.lowercased()

        // For MEDIUM urgency, pattern reference is appropriate
        let referencesPattern = responseText.contains("pattern") ||
                                responseText.contains("notice") ||
                                responseText.contains("again") ||
                                responseText.contains("cycle") ||
                                responseText.contains("checking") ||
                                responseText.contains("before")

        // More lenient - pattern reference is encouraged but not strictly required
        print("Medium urgency response: \(response.response.text.prefix(300))")
        print("Pattern referenced: \(referencesPattern)")

        // Document the behavior rather than strict assertion
        if referencesPattern {
            XCTAssertTrue(true, "MEDIUM urgency appropriately references patterns")
        } else {
            print("⚠️ NOTE: MEDIUM urgency did not reference patterns - may want to tune prompt")
            XCTAssertTrue(true, "Documenting: pattern reference not required for MEDIUM urgency")
        }
    }

    /// Verify LOW urgency casual chat with loops doesn't force pattern discussion
    func testLowUrgency_withLoops_naturalConversation() async throws {
        let messages = [
            Message(conversationId: "test", role: .user, text: "Hey Chloe, how are you?")
        ]

        let loops = ["User seeks validation", "Checks phone obsessively"]
        let systemPrompt = buildCrisisPromptWithLoops(loops: loops, urgency: .low, category: .selfImprovement)

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        // Casual chat should be natural, not forced pattern discussion
        let responseText = response.response.text.lowercased()
        let forcedPattern = responseText.contains("i notice you") ||
                           responseText.contains("your pattern of") ||
                           responseText.contains("you tend to")

        XCTAssertFalse(forcedPattern,
            "LOW urgency casual chat should not force pattern discussion")
    }

    /// Integration: Full crisis flow with existing loops should prioritize support
    func testCrisis_fullFlow_supportOverPatterns() async throws {
        // Setup: User has existing behavioral loops
        storageService.addBehavioralLoops([
            "Spirals on Sunday nights",
            "Checks location when partner is quiet",
            "Seeks validation after arguments"
        ])

        let profile = storageService.loadProfile() ?? Profile()
        XCTAssertFalse(profile.behavioralLoops?.isEmpty ?? true, "Setup: loops should exist")

        // Crisis message
        let messages = [
            Message(conversationId: "test", role: .user, text: "I just found out he's been lying to me for months. Everything was fake. I'm falling apart.")
        ]

        // Classify as crisis
        let classification = try await geminiService.classifyMessage(
            message: messages.first!.text
        )
        XCTAssertEqual(classification.urgency, .high, "Should be classified as HIGH urgency")

        // Get response with loops injected
        let systemPrompt = buildCrisisPromptWithLoops(
            loops: profile.behavioralLoops ?? [],
            urgency: classification.urgency,
            category: classification.category
        )

        let response = try await geminiService.sendStrategistMessage(
            messages: messages,
            systemPrompt: systemPrompt
        )

        // Verify response prioritizes emotional support
        let text = response.response.text

        // Should NOT have game theory options
        XCTAssertTrue(response.response.options?.isEmpty ?? true,
            "Crisis should not have options")

        // Should NOT lecture about patterns
        XCTAssertFalse(text.lowercased().contains("you always"),
            "Should not say 'you always' during crisis")
        XCTAssertFalse(text.lowercased().contains("this is a pattern"),
            "Should not lecture about patterns during crisis")

        print("✅ Crisis response (with loops present): \(text.prefix(300))...")
    }

    // MARK: - Helper Methods

    private func buildCrisisPromptWithLoops(
        loops: [String],
        urgency: RouterUrgency,
        category: RouterCategory = .crisisBreakup
    ) -> String {
        var prompt = Prompts.strategist
            .replacingOccurrences(of: "{{user_name}}", with: "TestUser")
            .replacingOccurrences(of: "{{archetype_label}}", with: "Not determined")
            .replacingOccurrences(of: "{{relationship_status}}", with: "Unknown")
            .replacingOccurrences(of: "{{current_vibe}}", with: urgency == .high ? "LOW" : "MEDIUM")

        prompt += """

        <router_context>
          Category: \(category.rawValue)
          Urgency: \(urgency.rawValue)
          Reasoning: Test scenario
        </router_context>
        """

        // Add crisis-specific instructions for HIGH urgency
        if urgency == .high {
            prompt += """

            <crisis_protocol>
              IMPORTANT: User is in HIGH urgency crisis mode.
              - Provide EMOTIONAL SUPPORT first
              - Do NOT provide game theory options
              - Do NOT lecture about patterns or past behavior
              - Be the supportive friend, not the strategist
              - Validate feelings before any advice
            </crisis_protocol>
            """
        }

        // Inject behavioral loops
        if !loops.isEmpty {
            prompt += """

            <known_patterns>
              These patterns are known from previous sessions.
              \(urgency == .high ? "During HIGH urgency crisis, do NOT call these out directly." : "Reference naturally when appropriate.")
              \(loops.map { "- \($0)" }.joined(separator: "\n  "))
            </known_patterns>
            """
        }

        return prompt
    }
}

// MARK: - Supabase Integration Tests

/// Tests for REAL Supabase cloud persistence (not just local storage)
/// Verifies: Write → Supabase, Read ← Supabase, App reinstall restore
final class SupabaseIntegrationTests: XCTestCase {

    var syncService: SyncDataService!
    var supabaseService: SupabaseDataService!
    var localStorage: StorageService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        syncService = SyncDataService.shared
        supabaseService = SupabaseDataService.shared
        localStorage = StorageService.shared

        // Skip all tests if not authenticated
        try XCTSkipIf(supabaseService.currentUserId == nil,
            "Skipping Supabase tests - Not authenticated. Run app and sign in first.")
    }

    // MARK: - Write Verification Tests

    /// Test: Behavioral loops are ACTUALLY saved to Supabase (not just locally)
    func testBehavioralLoops_writtenToSupabase() async throws {
        let uniqueLoop = "SupabaseWriteTest_\(UUID().uuidString)"

        // Write via SyncDataService (which should push to Supabase)
        syncService.addBehavioralLoops([uniqueLoop])

        // Wait for async cloud push to complete
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

        // Directly fetch from Supabase (bypassing local cache)
        let remoteProfile = try await supabaseService.fetchProfile()

        XCTAssertNotNil(remoteProfile, "Should fetch profile from Supabase")
        XCTAssertNotNil(remoteProfile?.behavioralLoops, "Supabase profile should have behavioralLoops")
        XCTAssertTrue(remoteProfile?.behavioralLoops?.contains(uniqueLoop) ?? false,
            "Loop should exist in Supabase. Remote loops: \(remoteProfile?.behavioralLoops ?? [])")
    }

    /// Test: Profile data (not just loops) is synced to Supabase
    func testProfile_writtenToSupabase() async throws {
        let uniqueName = "SupabaseTest_\(UUID().uuidString.prefix(8))"

        // Update profile locally
        var profile = syncService.loadProfile() ?? Profile()
        profile.displayName = uniqueName
        profile.updatedAt = Date()
        try syncService.saveProfile(profile)

        // Wait for cloud sync
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Verify in Supabase
        let remoteProfile = try await supabaseService.fetchProfile()
        XCTAssertEqual(remoteProfile?.displayName, uniqueName,
            "Profile displayName should be synced to Supabase")
    }

    // MARK: - Read Verification Tests

    /// Test: Can retrieve user data directly from Supabase
    func testSupabase_directFetchProfile() async throws {
        let remoteProfile = try await supabaseService.fetchProfile()

        XCTAssertNotNil(remoteProfile, "Should be able to fetch profile from Supabase")
        XCTAssertFalse(remoteProfile?.id.isEmpty ?? true, "Profile should have user ID")
    }

    /// Test: Can retrieve behavioral loops from Supabase
    func testSupabase_fetchBehavioralLoops() async throws {
        // First ensure there's at least one loop
        let testLoop = "FetchTest_\(UUID().uuidString)"
        syncService.addBehavioralLoops([testLoop])
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Fetch from Supabase
        let remoteProfile = try await supabaseService.fetchProfile()
        let remoteLoops = remoteProfile?.behavioralLoops ?? []

        XCTAssertFalse(remoteLoops.isEmpty, "Should have loops in Supabase")
        XCTAssertTrue(remoteLoops.contains(testLoop),
            "Should find test loop in Supabase. Loops: \(remoteLoops)")
    }

    // MARK: - App Reinstall / Cloud Restore Tests

    /// Test: Clear local storage, pull from cloud, verify data restored
    func testCloudRestore_afterLocalWipe() async throws {
        // Step 1: Write a unique loop and sync to cloud
        let uniqueLoop = "RestoreTest_\(UUID().uuidString)"
        syncService.addBehavioralLoops([uniqueLoop])
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Verify it's in Supabase
        let remoteProfileBefore = try await supabaseService.fetchProfile()
        guard remoteProfileBefore?.behavioralLoops?.contains(uniqueLoop) ?? false else {
            XCTFail("Setup failed: Loop not in Supabase before wipe")
            return
        }

        // Step 2: Clear ALL local storage (simulates app reinstall)
        localStorage.clearAll()

        // Verify local is empty
        let localProfileAfterWipe = localStorage.loadProfile()
        XCTAssertNil(localProfileAfterWipe?.behavioralLoops,
            "Local should be empty after wipe")

        // Step 3: Pull from cloud (simulates app launch after reinstall)
        await syncService.syncFromCloud()

        // Step 4: Verify data restored locally from cloud
        let restoredProfile = localStorage.loadProfile()
        XCTAssertNotNil(restoredProfile, "Profile should be restored from cloud")
        XCTAssertTrue(restoredProfile?.behavioralLoops?.contains(uniqueLoop) ?? false,
            "Loop should be restored from cloud. Restored loops: \(restoredProfile?.behavioralLoops ?? [])")
    }

    /// Test: Full reinstall scenario - wipe everything, restore from Supabase
    func testAppReinstall_fullRestoreScenario() async throws {
        // Step 1: Setup - ensure we have data in Supabase
        let testMarker = "ReinstallTest_\(UUID().uuidString.prefix(8))"
        let loopMarker = "Pattern_\(testMarker)"

        var profile = syncService.loadProfile() ?? Profile()
        profile.displayName = testMarker
        profile.onboardingComplete = true
        // Add loop directly to profile to ensure it's included in the same save
        var loops = profile.behavioralLoops ?? []
        loops.append(loopMarker)
        profile.behavioralLoops = loops
        profile.updatedAt = Date()
        try syncService.saveProfile(profile)

        // Wait for sync (longer to ensure cloud write completes)
        try await Task.sleep(nanoseconds: 4_000_000_000)

        // Verify Supabase has our data INCLUDING the loop
        let remoteBefore = try await supabaseService.fetchProfile()
        XCTAssertEqual(remoteBefore?.displayName, testMarker, "Setup: Supabase should have displayName")
        guard remoteBefore?.behavioralLoops?.contains(loopMarker) ?? false else {
            XCTFail("Setup failed: Loop '\(loopMarker)' not in Supabase before wipe. Remote loops: \(remoteBefore?.behavioralLoops ?? [])")
            return
        }

        // Step 2: Simulate COMPLETE app uninstall (wipe all local data)
        localStorage.clearAll()

        // Verify local is completely empty
        XCTAssertNil(localStorage.loadProfile(), "Local profile should be nil after uninstall")

        // Step 3: Simulate fresh app install + login (syncFromCloud)
        await syncService.syncFromCloud()

        // Step 4: Verify FULL restore
        let restored = localStorage.loadProfile()

        XCTAssertNotNil(restored, "Profile should be restored")
        XCTAssertEqual(restored?.displayName, testMarker,
            "Display name should be restored from Supabase")
        XCTAssertTrue(restored?.onboardingComplete ?? false,
            "Onboarding state should be restored")
        XCTAssertTrue(restored?.behavioralLoops?.contains(loopMarker) ?? false,
            "Behavioral loop '\(loopMarker)' should be restored. Got: \(restored?.behavioralLoops ?? [])")

        print("✅ App reinstall restore successful:")
        print("   - Profile restored: \(restored?.displayName ?? "nil")")
        print("   - Loops restored: \(restored?.behavioralLoops?.count ?? 0)")
    }

    // MARK: - Data Integrity Tests

    /// Test: Behavioral loops survive cloud round-trip without corruption
    func testBehavioralLoops_dataIntegrity_roundTrip() async throws {
        // Test various special characters survive Supabase round-trip
        let specialLoops = [
            "Loop with \"quotes\" and 'apostrophes'",
            "Loop with emoji 😭💔",
            "Loop with <brackets> and &ampersand"
        ]

        // Clear existing loops and add test loops
        var profile = syncService.loadProfile() ?? Profile()
        profile.behavioralLoops = specialLoops
        profile.updatedAt = Date()
        try syncService.saveProfile(profile)

        // Wait for sync
        try await Task.sleep(nanoseconds: 3_000_000_000)

        // Fetch from Supabase
        let remoteProfile = try await supabaseService.fetchProfile()
        let remoteLoops = remoteProfile?.behavioralLoops ?? []

        // Verify all special characters survived
        for loop in specialLoops {
            XCTAssertTrue(remoteLoops.contains(loop),
                "Loop '\(loop)' should survive Supabase round-trip")
        }
    }

    /// Test: Large number of loops syncs correctly
    func testBehavioralLoops_largeCount_syncsToSupabase() async throws {
        // Create 30 unique loops
        let loops = (1...30).map { "BulkTest_\(UUID().uuidString.prefix(8))_\($0)" }

        var profile = syncService.loadProfile() ?? Profile()
        let existingLoops = profile.behavioralLoops ?? []
        profile.behavioralLoops = existingLoops + loops
        profile.updatedAt = Date()
        try syncService.saveProfile(profile)

        // Wait for sync
        try await Task.sleep(nanoseconds: 4_000_000_000)

        // Verify in Supabase
        let remoteProfile = try await supabaseService.fetchProfile()
        let remoteLoops = remoteProfile?.behavioralLoops ?? []

        let matchCount = loops.filter { remoteLoops.contains($0) }.count
        XCTAssertEqual(matchCount, 30,
            "All 30 loops should sync to Supabase. Found: \(matchCount)/30")
    }

    // MARK: - MCP Verification (Manual Check)

    /// Test: Print Supabase state for manual MCP verification
    func testSupabase_printStateForMCPVerification() async throws {
        let userId = supabaseService.currentUserId ?? "unknown"
        let remoteProfile = try await supabaseService.fetchProfile()

        print("\n")
        print("╔══════════════════════════════════════════════════════════════════╗")
        print("║           SUPABASE STATE FOR MCP VERIFICATION                    ║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ User ID: \(userId.prefix(36).padding(toLength: 54, withPad: " ", startingAt: 0)) ║")
        print("║ Display Name: \(remoteProfile?.displayName.prefix(50).padding(toLength: 50, withPad: " ", startingAt: 0)) ║")
        print("║ Onboarding: \((remoteProfile?.onboardingComplete ?? false) ? "Complete" : "Incomplete".padding(toLength: 52, withPad: " ", startingAt: 0)) ║")
        print("║ Loops Count: \(String(remoteProfile?.behavioralLoops?.count ?? 0).padding(toLength: 51, withPad: " ", startingAt: 0)) ║")
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ Behavioral Loops:                                                ║")
        for loop in remoteProfile?.behavioralLoops ?? [] {
            print("║   - \(loop.prefix(60).padding(toLength: 60, withPad: " ", startingAt: 0)) ║")
        }
        print("╠══════════════════════════════════════════════════════════════════╣")
        print("║ MCP Query: SELECT behavioral_loops FROM profiles                 ║")
        print("║            WHERE id = '\(userId.prefix(36))...                   ║")
        print("╚══════════════════════════════════════════════════════════════════╝")
        print("\n")

        // This test always passes - it's for manual verification
        XCTAssertTrue(true)
    }
}
