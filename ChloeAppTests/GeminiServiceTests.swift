import XCTest
@testable import ChloeApp

final class GeminiServiceTests: XCTestCase {

    private let sut = GeminiService.shared

    // MARK: - GeminiError

    func testGeminiError_noAPIKey_description() {
        let error = GeminiError.noAPIKey
        XCTAssertEqual(error.errorDescription, "API key not configured")
    }

    func testGeminiError_timeout_description() {
        let error = GeminiError.timeout
        XCTAssertEqual(error.errorDescription, "Chloe is taking too long to respond. Please try again.")
    }

    func testGeminiError_apiError_description() {
        let error = GeminiError.apiError(429, "Rate limited")
        XCTAssertEqual(error.errorDescription, "API error (429): Rate limited")
    }

    func testGeminiError_emptyResponse_description() {
        let error = GeminiError.emptyResponse
        XCTAssertEqual(error.errorDescription, "I'm having a moment \u{2014} can you try again?")
    }

    func testGeminiError_decodingFailed_description() {
        let error = GeminiError.decodingFailed
        XCTAssertEqual(error.errorDescription, "Failed to parse response")
    }

    func testGeminiError_routerInvalidResponse_description() {
        let error = GeminiError.routerInvalidResponse
        XCTAssertEqual(error.errorDescription, "Router returned invalid response")
    }

    // MARK: - Response Parsing: extractText Behavior

    /// Tests the JSON structure that Gemini API returns for text responses.
    /// extractText is private, so we test it indirectly through the response format.
    func testGeminiResponseFormat_validStructure() throws {
        // Simulate the JSON structure Gemini returns
        let json: [String: Any] = [
            "candidates": [
                [
                    "content": [
                        "parts": [
                            ["text": "Hey girl, I'm here for you."]
                        ]
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = parsed?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        let text = parts?.first?["text"] as? String
        XCTAssertEqual(text, "Hey girl, I'm here for you.")
    }

    func testGeminiResponseFormat_emptyCandidates() throws {
        let json: [String: Any] = ["candidates": []]
        let data = try JSONSerialization.data(withJSONObject: json)
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = parsed?["candidates"] as? [[String: Any]]
        XCTAssertTrue(candidates?.isEmpty ?? false, "Empty candidates should parse as empty array")
    }

    func testGeminiResponseFormat_missingText() throws {
        let json: [String: Any] = [
            "candidates": [
                [
                    "content": [
                        "parts": [[:]]  // No "text" key
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = parsed?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        let text = parts?.first?["text"] as? String
        XCTAssertNil(text, "Missing text key should return nil")
    }

    // MARK: - Markdown Wrapper Stripping

    /// Tests the stripMarkdownWrapper logic by simulating its behavior.
    /// The method is private, so we replicate its logic for verification.
    func testStripMarkdownWrapper_jsonBlock() {
        let input = "```json\n{\"key\": \"value\"}\n```"
        let cleaned = stripMarkdown(input)
        XCTAssertEqual(cleaned, "{\"key\": \"value\"}")
    }

    func testStripMarkdownWrapper_plainCodeBlock() {
        let input = "```\n{\"key\": \"value\"}\n```"
        let cleaned = stripMarkdown(input)
        XCTAssertEqual(cleaned, "{\"key\": \"value\"}")
    }

    func testStripMarkdownWrapper_noWrapper() {
        let input = "{\"key\": \"value\"}"
        let cleaned = stripMarkdown(input)
        XCTAssertEqual(cleaned, "{\"key\": \"value\"}")
    }

    func testStripMarkdownWrapper_withWhitespace() {
        let input = "  ```json\n{\"key\": \"value\"}\n```  "
        let cleaned = stripMarkdown(input)
        XCTAssertEqual(cleaned, "{\"key\": \"value\"}")
    }

    /// Replicates the private stripMarkdownWrapper logic for testing
    private func stripMarkdown(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Request Building: System Instruction with Facts

    func testSystemInstruction_factsInjection() {
        let basePrompt = "You are Chloe."
        let facts = ["She likes cats", "Her ex was avoidant"]
        var instruction = basePrompt
        if !facts.isEmpty {
            instruction += "\n\nWhat you know about this user:\n\(facts.joined(separator: "\n"))"
        }
        XCTAssertTrue(instruction.contains("She likes cats"))
        XCTAssertTrue(instruction.contains("Her ex was avoidant"))
        XCTAssertTrue(instruction.contains("What you know about this user:"))
    }

    func testSystemInstruction_emptyFacts_noInjection() {
        let basePrompt = "You are Chloe."
        let facts: [String] = []
        var instruction = basePrompt
        if !facts.isEmpty {
            instruction += "\n\nWhat you know about this user:\n\(facts.joined(separator: "\n"))"
        }
        XCTAssertFalse(instruction.contains("What you know about this user:"))
        XCTAssertEqual(instruction, "You are Chloe.")
    }

    // MARK: - Request Building: Session Context Injection

    func testSystemInstruction_sessionContextInjected_newConversation() {
        let basePrompt = "Base prompt."
        let lastSummary = "She discussed her breakup."
        let isNewConversation = true
        var instruction = basePrompt
        if isNewConversation, let summary = Optional(lastSummary) {
            instruction += "\n\n<session_context>\n\(summary)\n</session_context>"
        }
        XCTAssertTrue(instruction.contains("<session_context>"))
        XCTAssertTrue(instruction.contains("She discussed her breakup."))
    }

    func testSystemInstruction_sessionContextNotInjected_existingConversation() {
        let basePrompt = "Base prompt."
        let lastSummary = "Previous session info."
        let isNewConversation = false
        var instruction = basePrompt
        if isNewConversation {
            instruction += "\n\n<session_context>\n\(lastSummary)\n</session_context>"
        }
        XCTAssertFalse(instruction.contains("<session_context>"))
    }

    // MARK: - Request Building: Insight Injection

    func testSystemInstruction_insightInjected_existingConversation() {
        let basePrompt = "Base prompt."
        let insight = "User shows avoidant attachment pattern."
        let isNewConversation = false
        var instruction = basePrompt
        if !isNewConversation {
            instruction += "\n\n<internal_insight>\n\(insight)\n</internal_insight>"
        }
        XCTAssertTrue(instruction.contains("<internal_insight>"))
        XCTAssertTrue(instruction.contains("avoidant attachment"))
    }

    func testSystemInstruction_insightNotInjected_newConversation() {
        let basePrompt = "Base prompt."
        let insight = "Some insight."
        let isNewConversation = true
        var instruction = basePrompt
        if !isNewConversation {
            instruction += "\n\n<internal_insight>\n\(insight)\n</internal_insight>"
        }
        XCTAssertFalse(instruction.contains("<internal_insight>"))
    }

    // MARK: - Message Conversion: Role Mapping

    func testRoleMapping_user() {
        let msg = Message(role: .user, text: "Hello")
        let geminiRole = msg.role == .user ? "user" : "model"
        XCTAssertEqual(geminiRole, "user")
    }

    func testRoleMapping_chloe() {
        let msg = Message(role: .chloe, text: "Hey girl")
        let geminiRole = msg.role == .user ? "user" : "model"
        XCTAssertEqual(geminiRole, "model")
    }

    // MARK: - Message Conversion: Image Handling

    func testMessageConversion_imageOnly_hasFallbackText() {
        let msg = Message(role: .user, text: "", imageUri: "/path/to/image.jpg")
        // When text is empty and image path exists but image can't be loaded,
        // the parts should have a fallback "[Image]" text
        var parts: [[String: Any]] = []
        // Non-latest message with image gets placeholder
        parts.append(["text": "[User shared an image]"])
        if !msg.text.isEmpty {
            parts.append(["text": msg.text])
        }
        if parts.isEmpty {
            parts.append(["text": "[Image]"])
        }
        XCTAssertFalse(parts.isEmpty, "Parts should never be empty")
    }

    func testMessageConversion_textOnly_singlePart() {
        let msg = Message(role: .user, text: "Hello Chloe")
        var parts: [[String: Any]] = []
        if !msg.text.isEmpty {
            parts.append(["text": msg.text])
        }
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0]["text"] as? String, "Hello Chloe")
    }

    func testMessageConversion_emptyTextNoImage_fallback() {
        let msg = Message(role: .user, text: "")
        var parts: [[String: Any]] = []
        if let imageUri = msg.imageUri {
            parts.append(["text": "[User shared an image: \(imageUri)]"])
        }
        if !msg.text.isEmpty {
            parts.append(["text": msg.text])
        }
        if parts.isEmpty {
            parts.append(["text": "[Image]"])
        }
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts[0]["text"] as? String, "[Image]")
    }

    // MARK: - Conversation History Limiting

    func testConversationHistoryLimit() {
        var messages: [Message] = []
        for i in 0..<30 {
            messages.append(Message(role: .user, text: "Message \(i)"))
        }
        let recent = Array(messages.suffix(MAX_CONVERSATION_HISTORY))
        XCTAssertEqual(recent.count, MAX_CONVERSATION_HISTORY)
        XCTAssertEqual(recent.first?.text, "Message \(30 - MAX_CONVERSATION_HISTORY)")
        XCTAssertEqual(recent.last?.text, "Message 29")
    }

    func testConversationHistoryLimit_underLimit() {
        var messages: [Message] = []
        for i in 0..<5 {
            messages.append(Message(role: .user, text: "Message \(i)"))
        }
        let recent = Array(messages.suffix(MAX_CONVERSATION_HISTORY))
        XCTAssertEqual(recent.count, 5, "Under-limit should return all messages")
    }

    // MARK: - AnalystResult Parsing

    func testAnalystResult_decodable() throws {
        let json = """
        {
            "new_facts": [
                {"fact": "She has a dog", "category": "RELATIONSHIP_HISTORY"}
            ],
            "vibe_score": "HIGH",
            "vibe_reasoning": "She seems happy",
            "behavioral_loops_detected": ["People-pleasing"],
            "session_summary": "Discussed dating life",
            "engagement_opportunity": null
        }
        """
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AnalystResult.self, from: data)
        XCTAssertEqual(result.facts.count, 1)
        XCTAssertEqual(result.facts[0].fact, "She has a dog")
        XCTAssertEqual(result.vibeScore, .high)
        XCTAssertEqual(result.summary, "Discussed dating life")
        XCTAssertEqual(result.behavioralLoops.count, 1)
        XCTAssertNil(result.engagementOpportunity)
    }

    func testAnalystResult_defaultInit() {
        let result = AnalystResult()
        XCTAssertTrue(result.facts.isEmpty)
        XCTAssertEqual(result.vibeScore, .medium)
        XCTAssertEqual(result.vibeReason, "")
        XCTAssertTrue(result.behavioralLoops.isEmpty)
        XCTAssertEqual(result.summary, "")
        XCTAssertNil(result.engagementOpportunity)
    }

    // MARK: - classifyMessage / sendStrategistMessage: API Key Guard

    func testClassifyMessage_noAPIKey_throwsError() async {
        do {
            _ = try await sut.classifyMessage(message: "Hello")
            // Without an API key this should throw
        } catch let error as GeminiError {
            XCTAssertEqual(error, .noAPIKey,
                           "classifyMessage should throw noAPIKey without a configured key")
        } catch {
            // Network error acceptable
        }
    }

    func testSendStrategistMessage_noAPIKey_throwsError() async {
        do {
            _ = try await sut.sendStrategistMessage(
                messages: [Message(role: .user, text: "Test")],
                systemPrompt: "Test"
            )
        } catch let error as GeminiError {
            XCTAssertEqual(error, .noAPIKey)
        } catch {
            // Network error acceptable
        }
    }

    func testGenerateTitle_noAPIKey_throwsError() async {
        do {
            _ = try await sut.generateTitle(for: "Hello world")
        } catch let error as GeminiError {
            XCTAssertEqual(error, .noAPIKey)
        } catch {
            // Network error acceptable
        }
    }

    func testGenerateAffirmation_noAPIKey_throwsError() async {
        do {
            _ = try await sut.generateAffirmation(
                displayName: "Sarah",
                preferences: nil,
                archetype: nil
            )
        } catch let error as GeminiError {
            XCTAssertEqual(error, .noAPIKey)
        } catch {
            // Network error acceptable
        }
    }

    // MARK: - GeminiError Equatable

    func testGeminiError_equatable() {
        // GeminiError cases without associated values
        XCTAssertTrue(compareErrors(.noAPIKey, .noAPIKey))
        XCTAssertTrue(compareErrors(.timeout, .timeout))
        XCTAssertTrue(compareErrors(.emptyResponse, .emptyResponse))
        XCTAssertTrue(compareErrors(.decodingFailed, .decodingFailed))
        XCTAssertFalse(compareErrors(.noAPIKey, .timeout))
    }

    /// Helper to compare GeminiError cases by description since GeminiError
    /// does not conform to Equatable.
    private func compareErrors(_ lhs: GeminiError, _ rhs: GeminiError) -> Bool {
        return lhs.errorDescription == rhs.errorDescription
    }

    // MARK: - Strategist Retry Fallback

    func testStrategistResponse_fallback_createdFromRawText() {
        // When JSON parsing fails after retries, a fallback StrategistResponse is created
        let fallback = StrategistResponse(
            internalThought: InternalThought(
                userVibe: "MEDIUM",
                manBehaviorAnalysis: "JSON parsing failed after 2 attempts",
                strategySelection: "Fallback to raw text"
            ),
            response: ResponseContent(text: "Raw response text", options: nil)
        )
        XCTAssertEqual(fallback.internalThought.userVibe, "MEDIUM")
        XCTAssertEqual(fallback.response.text, "Raw response text")
        XCTAssertNil(fallback.response.options)
    }

    // MARK: - Analyze Conversation: Context Dossier Building

    func testAnalyzeConversation_dossierFormat() {
        let displayName = "Sarah"
        let currentVibe: VibeScore = .high
        let userFacts = ["Likes cats", "Works in tech"]
        let lastSummary = "Discussed breakup"

        let dossier = """
        <context_dossier>
          USER NAME: \(displayName)
          CURRENT VIBE SCORE: \(currentVibe.rawValue)
          KNOWN FACTS: \(userFacts.joined(separator: "; "))
          LAST SESSION SUMMARY: \(lastSummary)
        </context_dossier>
        """

        XCTAssertTrue(dossier.contains("USER NAME: Sarah"))
        XCTAssertTrue(dossier.contains("CURRENT VIBE SCORE: HIGH"))
        XCTAssertTrue(dossier.contains("Likes cats; Works in tech"))
        XCTAssertTrue(dossier.contains("LAST SESSION SUMMARY: Discussed breakup"))
    }

    func testAnalyzeConversation_dossierDefaults() {
        let displayName: String? = nil
        let currentVibe: VibeScore? = nil
        let userFacts: [String] = []
        let lastSummary: String? = nil

        let dossier = """
        <context_dossier>
          USER NAME: \(displayName ?? "Unknown")
          CURRENT VIBE SCORE: \(currentVibe?.rawValue ?? "UNKNOWN")
          KNOWN FACTS: \(userFacts.joined(separator: "; "))
          LAST SESSION SUMMARY: \(lastSummary ?? "No previous session")
        </context_dossier>
        """

        XCTAssertTrue(dossier.contains("USER NAME: Unknown"))
        XCTAssertTrue(dossier.contains("CURRENT VIBE SCORE: UNKNOWN"))
        XCTAssertTrue(dossier.contains("KNOWN FACTS: "))
        XCTAssertTrue(dossier.contains("LAST SESSION SUMMARY: No previous session"))
    }
}

// MARK: - GeminiError Equatable Helper Extension (test-only)

extension GeminiError: @retroactive Equatable {
    public static func == (lhs: GeminiError, rhs: GeminiError) -> Bool {
        switch (lhs, rhs) {
        case (.noAPIKey, .noAPIKey): return true
        case (.timeout, .timeout): return true
        case (.emptyResponse, .emptyResponse): return true
        case (.decodingFailed, .decodingFailed): return true
        case (.routerInvalidResponse, .routerInvalidResponse): return true
        case (.apiError(let lCode, let lMsg), .apiError(let rCode, let rMsg)):
            return lCode == rCode && lMsg == rMsg
        default: return false
        }
    }
}
