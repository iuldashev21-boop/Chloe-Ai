import Foundation

// MARK: - Router Classification (Triage)

/// The category classification from the Context Router
enum RouterCategory: String, Codable {
    case crisisBreakup = "CRISIS_BREAKUP"
    case datingEarly = "DATING_EARLY"
    case relationshipEstablished = "RELATIONSHIP_ESTABLISHED"
    case selfImprovement = "SELF_IMPROVEMENT"
    case safetyRisk = "SAFETY_RISK"
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

/// The structured JSON response from the Strategist
struct StrategistResponse: Codable {
    var internalThought: InternalThought
    var response: ResponseContent

    enum CodingKeys: String, CodingKey {
        case internalThought = "internal_thought"
        case response
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

/// The user-facing response content
struct ResponseContent: Codable {
    var text: String
    var options: [StrategyOption]?
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
