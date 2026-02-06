import XCTest
@testable import ChloeApp

final class MessageModelTests: XCTestCase {

    // MARK: - UUID Lowercasing in Init

    func testInit_idIsLowercased() {
        let msg = Message(id: "ABC123-DEF456", role: .user, text: "Hello")
        XCTAssertEqual(msg.id, "abc123-def456", "ID should be lowercased on init")
    }

    func testInit_alreadyLowercased_unchanged() {
        let msg = Message(id: "abc123", role: .user, text: "Hello")
        XCTAssertEqual(msg.id, "abc123")
    }

    func testInit_mixedCaseUUID_lowercased() {
        let uuid = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let msg = Message(id: uuid, role: .user, text: "Test")
        XCTAssertEqual(msg.id, uuid.lowercased())
    }

    func testInit_conversationIdIsLowercased() {
        let msg = Message(conversationId: "CONVO-ABC", role: .user, text: "Hello")
        XCTAssertEqual(msg.conversationId, "convo-abc", "Conversation ID should be lowercased on init")
    }

    func testInit_conversationIdNil_staysNil() {
        let msg = Message(conversationId: nil, role: .user, text: "Hello")
        XCTAssertNil(msg.conversationId)
    }

    func testInit_defaultId_isLowercased() {
        let msg = Message(role: .user, text: "Hello")
        XCTAssertEqual(msg.id, msg.id.lowercased(), "Default UUID should be lowercased")
    }

    // MARK: - Content Type Handling

    func testContentType_text() {
        let msg = Message(role: .chloe, text: "Hey girl", contentType: .text)
        XCTAssertEqual(msg.contentType, .text)
    }

    func testContentType_optionPair() {
        let options = [
            StrategyOption(label: "Option A", action: "Do A", outcome: "Result A"),
            StrategyOption(label: "Option B", action: "Do B", outcome: "Result B")
        ]
        let msg = Message(role: .chloe, text: "Choose wisely", contentType: .optionPair, options: options)
        XCTAssertEqual(msg.contentType, .optionPair)
        XCTAssertEqual(msg.options?.count, 2)
        XCTAssertEqual(msg.options?[0].label, "Option A")
    }

    func testContentType_nilByDefault() {
        let msg = Message(role: .user, text: "Hello")
        XCTAssertNil(msg.contentType)
    }

    // MARK: - MessageContentType Raw Values

    func testMessageContentType_textRawValue() {
        XCTAssertEqual(MessageContentType.text.rawValue, "text")
    }

    func testMessageContentType_optionPairRawValue() {
        XCTAssertEqual(MessageContentType.optionPair.rawValue, "option_pair")
    }

    // MARK: - RouterMetadata Serialization

    func testRouterMetadata_encodeDecode() throws {
        let metadata = RouterMetadata(
            internalThought: "User is spiraling about ex",
            routerMode: "CRISIS_BREAKUP",
            selectedOption: "Option A"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RouterMetadata.self, from: data)

        XCTAssertEqual(decoded.internalThought, "User is spiraling about ex")
        XCTAssertEqual(decoded.routerMode, "CRISIS_BREAKUP")
        XCTAssertEqual(decoded.selectedOption, "Option A")
    }

    func testRouterMetadata_nilFields_encodeDecode() throws {
        let metadata = RouterMetadata(internalThought: nil, routerMode: nil, selectedOption: nil)
        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RouterMetadata.self, from: data)

        XCTAssertNil(decoded.internalThought)
        XCTAssertNil(decoded.routerMode)
        XCTAssertNil(decoded.selectedOption)
    }

    func testRouterMetadata_codingKeys() throws {
        // Verify JSON uses snake_case keys
        let metadata = RouterMetadata(
            internalThought: "thought",
            routerMode: "mode",
            selectedOption: "opt"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["internal_thought"])
        XCTAssertNotNil(json?["router_mode"])
        XCTAssertNotNil(json?["selected_option"])
    }

    // MARK: - Message with RouterMetadata

    func testMessage_withRouterMetadata_encodeDecode() throws {
        let metadata = RouterMetadata(
            internalThought: "Analysis",
            routerMode: "DATING_EARLY",
            selectedOption: nil
        )
        let original = Message(
            id: "m1",
            conversationId: "c1",
            role: .chloe,
            text: "Hey girl",
            routerMetadata: metadata,
            contentType: .text
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Message.self, from: data)

        XCTAssertEqual(decoded.id, "m1")
        XCTAssertEqual(decoded.conversationId, "c1")
        XCTAssertEqual(decoded.role, .chloe)
        XCTAssertEqual(decoded.text, "Hey girl")
        XCTAssertEqual(decoded.routerMetadata?.routerMode, "DATING_EARLY")
        XCTAssertEqual(decoded.contentType, .text)
    }

    // MARK: - Image URI Handling

    func testImageUri_stored() {
        let msg = Message(role: .user, text: "Look at this", imageUri: "/path/to/image.jpg")
        XCTAssertEqual(msg.imageUri, "/path/to/image.jpg")
    }

    func testImageUri_nilByDefault() {
        let msg = Message(role: .user, text: "Hello")
        XCTAssertNil(msg.imageUri)
    }

    func testImageUri_encodeDecode() throws {
        let original = Message(
            id: "m1",
            role: .user,
            text: "Check this",
            imageUri: "/var/docs/chat_abc.jpg"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Message.self, from: data)

        XCTAssertEqual(decoded.imageUri, "/var/docs/chat_abc.jpg")
    }

    // MARK: - MessageRole

    func testMessageRole_userRawValue() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
    }

    func testMessageRole_chloeRawValue() {
        XCTAssertEqual(MessageRole.chloe.rawValue, "chloe")
    }

    func testMessageRole_decodable() throws {
        let json = #"{"id":"m1","role":"chloe","text":"Hey","createdAt":"2025-01-01T00:00:00Z"}"#
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let msg = try decoder.decode(Message.self, from: data)
        XCTAssertEqual(msg.role, .chloe)
    }

    // MARK: - Default Values

    func testDefaults_createdAtIsNow() {
        let before = Date()
        let msg = Message(role: .user, text: "Test")
        let after = Date()
        XCTAssertGreaterThanOrEqual(msg.createdAt, before)
        XCTAssertLessThanOrEqual(msg.createdAt, after)
    }

    func testDefaults_optionsNil() {
        let msg = Message(role: .chloe, text: "Response")
        XCTAssertNil(msg.options)
    }

    func testDefaults_routerMetadataNil() {
        let msg = Message(role: .chloe, text: "Response")
        XCTAssertNil(msg.routerMetadata)
    }

    // MARK: - Identifiable Conformance

    func testIdentifiable_idMatchesInit() {
        let msg = Message(id: "unique-id", role: .user, text: "Hello")
        XCTAssertEqual(msg.id, "unique-id")
    }

    // MARK: - Full Round-Trip Encode/Decode

    func testFullMessage_roundTrip() throws {
        let options = [
            StrategyOption(label: "A", action: "Do A", outcome: "Result A")
        ]
        let metadata = RouterMetadata(
            internalThought: "Thought",
            routerMode: "SELF_IMPROVEMENT",
            selectedOption: "A"
        )
        let original = Message(
            id: "M1",
            conversationId: "C1",
            role: .chloe,
            text: "Advice text",
            imageUri: "/img.jpg",
            routerMetadata: metadata,
            contentType: .optionPair,
            options: options
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Message.self, from: data)

        // Note: IDs are lowercased on init, but decode bypasses init
        XCTAssertEqual(decoded.role, .chloe)
        XCTAssertEqual(decoded.text, "Advice text")
        XCTAssertEqual(decoded.imageUri, "/img.jpg")
        XCTAssertEqual(decoded.contentType, .optionPair)
        XCTAssertEqual(decoded.options?.count, 1)
        XCTAssertEqual(decoded.routerMetadata?.routerMode, "SELF_IMPROVEMENT")
    }

    // MARK: - StrategyOption Serialization

    func testStrategyOption_outcomeKey() throws {
        let json = #"{"label":"A","action":"Act","outcome":"Result"}"#
        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(StrategyOption.self, from: data)
        XCTAssertEqual(option.label, "A")
        XCTAssertEqual(option.action, "Act")
        XCTAssertEqual(option.outcome, "Result")
    }

    func testStrategyOption_predictedOutcomeKey() throws {
        let json = #"{"label":"B","action":"Act B","predicted_outcome":"Predicted"}"#
        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(StrategyOption.self, from: data)
        XCTAssertEqual(option.outcome, "Predicted",
                       "predicted_outcome should map to outcome property")
    }

    func testStrategyOption_noOutcomeKey_defaultsToEmpty() throws {
        let json = #"{"label":"C","action":"Act C"}"#
        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(StrategyOption.self, from: data)
        XCTAssertEqual(option.outcome, "",
                       "Missing outcome keys should default to empty string")
    }

    func testStrategyOption_identifiable_idIsLabel() {
        let option = StrategyOption(label: "Test Label", action: "Act", outcome: "Out")
        XCTAssertEqual(option.id, "Test Label")
    }

    func testStrategyOption_encodesAsPredictedOutcome() throws {
        let option = StrategyOption(label: "A", action: "Act", outcome: "Out")
        let data = try JSONEncoder().encode(option)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["predicted_outcome"],
                        "Encoder should output predicted_outcome key")
        XCTAssertNil(json?["outcome"],
                     "Encoder should not output outcome key")
    }

    // MARK: - RouterClassification

    func testRouterClassification_decodable() throws {
        let json = """
        {"category":"CRISIS_BREAKUP","urgency":"HIGH","reasoning":"User just broke up"}
        """
        let data = json.data(using: .utf8)!
        let classification = try JSONDecoder().decode(RouterClassification.self, from: data)
        XCTAssertEqual(classification.category, .crisisBreakup)
        XCTAssertEqual(classification.urgency, .high)
        XCTAssertEqual(classification.reasoning, "User just broke up")
    }

    func testRouterCategory_allCases() {
        XCTAssertEqual(RouterCategory.crisisBreakup.rawValue, "CRISIS_BREAKUP")
        XCTAssertEqual(RouterCategory.datingEarly.rawValue, "DATING_EARLY")
        XCTAssertEqual(RouterCategory.relationshipEstablished.rawValue, "RELATIONSHIP_ESTABLISHED")
        XCTAssertEqual(RouterCategory.selfImprovement.rawValue, "SELF_IMPROVEMENT")
        XCTAssertEqual(RouterCategory.safetyRisk.rawValue, "SAFETY_RISK")
    }

    func testRouterUrgency_allCases() {
        XCTAssertEqual(RouterUrgency.low.rawValue, "LOW")
        XCTAssertEqual(RouterUrgency.medium.rawValue, "MEDIUM")
        XCTAssertEqual(RouterUrgency.high.rawValue, "HIGH")
    }

    // MARK: - StrategistResponse Flexible Decoding

    func testStrategistResponse_objectInternalThought() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "HIGH",
                "man_behavior_analysis": "He is love-bombing",
                "strategy_selection": "Mirror his energy"
            },
            "response": {
                "text": "Girl, let me tell you something."
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)
        XCTAssertEqual(response.internalThought.userVibe, "HIGH")
        XCTAssertEqual(response.internalThought.manBehaviorAnalysis, "He is love-bombing")
        XCTAssertEqual(response.response.text, "Girl, let me tell you something.")
    }

    func testStrategistResponse_stringInternalThought() throws {
        let json = """
        {
            "internal_thought": "Just some raw text from the LLM",
            "response": {
                "text": "Response text here"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)
        XCTAssertEqual(response.internalThought.userVibe, "UNKNOWN")
        XCTAssertEqual(response.internalThought.strategySelection, "Just some raw text from the LLM")
        XCTAssertEqual(response.response.text, "Response text here")
    }

    func testStrategistResponse_responseAsString() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "LOW",
                "man_behavior_analysis": "N/A",
                "strategy_selection": "Support"
            },
            "response": "Just a plain string response"
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)
        XCTAssertEqual(response.response.text, "Just a plain string response")
        XCTAssertNil(response.response.options)
    }

    func testResponseContent_adviceKey_mapsToText() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "MEDIUM",
                "man_behavior_analysis": "N/A",
                "strategy_selection": "Direct"
            },
            "response": {
                "advice": "This is advice, not text key"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)
        XCTAssertEqual(response.response.text, "This is advice, not text key",
                       "advice key should map to text property")
    }

    func testResponseContent_withOptions() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "HIGH",
                "man_behavior_analysis": "Avoidant",
                "strategy_selection": "Present options"
            },
            "response": {
                "text": "Here are your options",
                "options": [
                    {"label": "Option 1", "action": "Do this", "predicted_outcome": "Good result"},
                    {"label": "Option 2", "action": "Do that", "outcome": "Other result"}
                ]
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)
        XCTAssertEqual(response.response.options?.count, 2)
        XCTAssertEqual(response.response.options?[0].outcome, "Good result")
        XCTAssertEqual(response.response.options?[1].outcome, "Other result")
    }

    func testResponseContent_noTextOrAdvice_fallsBackToDefault() throws {
        let json = """
        {
            "internal_thought": {
                "user_vibe": "LOW",
                "man_behavior_analysis": "N/A",
                "strategy_selection": "Fallback"
            },
            "response": {
                "some_other_key": "unexpected"
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(StrategistResponse.self, from: data)
        XCTAssertEqual(response.response.text, "I'm here for you.",
                       "Should fall back to default text when no text or advice key")
    }

    // MARK: - ResponseContent Encoder

    func testResponseContent_alwaysEncodesAsText() throws {
        let content = ResponseContent(text: "Test response", options: nil)
        let data = try JSONEncoder().encode(content)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["text"])
        XCTAssertNil(json?["advice"], "Encoder should not use advice key")
    }
}
