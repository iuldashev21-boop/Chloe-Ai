import Foundation

// MARK: - Router Classification (Triage)

/// The category classification from the Context Router
enum RouterCategory: String, Codable {
    case crisisBreakup = "CRISIS_BREAKUP"
    case datingEarly = "DATING_EARLY"
    case relationshipEstablished = "RELATIONSHIP_ESTABLISHED"
    case selfImprovement = "SELF_IMPROVEMENT"
    case safetyRisk = "SAFETY_RISK"
    case casual = "CASUAL"
}

/// The urgency level from the Context Router
enum RouterUrgency: String, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

/// The classification result from the Context Router
struct RouterClassification: Codable {
    var category: RouterCategory
    var urgency: RouterUrgency
    var reasoning: String
}

// MARK: - Strategist Response (v2 Agentic)

/// The structured JSON response from the Strategist (v2.2 - Flexible Decoding)
struct StrategistResponse: Codable {
    var internalThought: InternalThought
    var response: ResponseContent

    enum CodingKeys: String, CodingKey {
        case internalThought = "internal_thought"
        case response
    }

    // FIX 3: Flexible decoder - handles internal_thought as Object OR String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.response = try container.decode(ResponseContent.self, forKey: .response)

        // Try decoding as Object first (expected format)
        if let objectThought = try? container.decode(InternalThought.self, forKey: .internalThought) {
            self.internalThought = objectThought
        }
        // Fallback: If model returned a String, wrap it in our struct
        else if let stringThought = try? container.decode(String.self, forKey: .internalThought) {
            self.internalThought = InternalThought(
                userVibe: "UNKNOWN",
                manBehaviorAnalysis: "N/A",
                strategySelection: stringThought
            )
        }
        // Final fallback: parsing error
        else {
            self.internalThought = InternalThought(
                userVibe: "UNKNOWN",
                manBehaviorAnalysis: "N/A",
                strategySelection: "Parsing Error"
            )
        }
    }

    // Standard initializer for creating responses in code
    init(internalThought: InternalThought, response: ResponseContent) {
        self.internalThought = internalThought
        self.response = response
    }
}

/// The strategist's internal reasoning (not shown to user)
struct InternalThought: Codable {
    var userVibe: String
    var manBehaviorAnalysis: String
    var strategySelection: String

    enum CodingKeys: String, CodingKey {
        case userVibe = "user_vibe"
        case manBehaviorAnalysis = "man_behavior_analysis"
        case strategySelection = "strategy_selection"
    }
}

/// The user-facing response content (v2.2 - Flexible Decoding)
struct ResponseContent: Codable {
    var text: String
    var options: [StrategyOption]?

    enum CodingKeys: String, CodingKey {
        case text
        case advice  // FIX 7: LLM sometimes uses "advice" instead of "text"
        case options
    }

    // FIX 7: Flexible decoder - handles response as Object OR String
    init(from decoder: Decoder) throws {
        // First, try decoding as a plain String (LLM glitch)
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            self.text = stringValue
            self.options = nil
            return
        }

        // Otherwise, decode as Object with flexible key handling
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try "text" first, then "advice" as fallback
        if let textValue = try? container.decode(String.self, forKey: .text) {
            self.text = textValue
        } else if let adviceValue = try? container.decode(String.self, forKey: .advice) {
            self.text = adviceValue
        } else {
            self.text = "I'm here for you."  // Ultimate fallback
        }

        self.options = try container.decodeIfPresent([StrategyOption].self, forKey: .options)
    }

    // Standard initializer for creating responses in code
    init(text: String, options: [StrategyOption]? = nil) {
        self.text = text
        self.options = options
    }

    // Custom encoder to always output "text" (not "advice")
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(options, forKey: .options)
    }
}

/// A strategic option presented to the user
struct StrategyOption: Codable, Identifiable {
    var id: String { label }
    var label: String
    var action: String
    var outcome: String

    enum CodingKeys: String, CodingKey {
        case label
        case action
        case outcome
        case predictedOutcome = "predicted_outcome"
    }

    // Custom decoder to handle both "outcome" and "predicted_outcome" keys
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        action = try container.decode(String.self, forKey: .action)
        // Try "outcome" first, then "predicted_outcome", then empty string
        outcome = try container.decodeIfPresent(String.self, forKey: .outcome)
            ?? container.decodeIfPresent(String.self, forKey: .predictedOutcome)
            ?? ""
    }

    // Custom encoder to always output "predicted_outcome"
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(action, forKey: .action)
        try container.encode(outcome, forKey: .predictedOutcome)
    }

    // Standard initializer for creating options in code
    init(label: String, action: String, outcome: String) {
        self.label = label
        self.action = action
        self.outcome = outcome
    }
}

// MARK: - Router Metadata (for storage)

/// Metadata stored alongside messages for agentic context
struct RouterMetadata: Codable {
    var internalThought: String?
    var routerMode: String?
    var selectedOption: String?

    enum CodingKeys: String, CodingKey {
        case internalThought = "internal_thought"
        case routerMode = "router_mode"
        case selectedOption = "selected_option"
    }
}

// MARK: - Message Content Type

/// Indicates the type of content in a message
enum MessageContentType: String, Codable {
    case text
    case optionPair = "option_pair"
}
