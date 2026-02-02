import Foundation

enum ArchetypeId: String, Codable, CaseIterable {
    case siren
    case queen
    case muse
    case lover
    case sage
    case rebel
    case warrior
}

struct UserArchetype: Codable {
    var primary: ArchetypeId
    var secondary: ArchetypeId
    var label: String
    var blend: String
    var description: String
}

struct AnalystResult: Codable {
    var facts: [ExtractedFact]
    var vibeScore: VibeScore
    var vibeReason: String
    var summary: String
    var engagementOpportunity: EngagementOpportunity?

    enum CodingKeys: String, CodingKey {
        case facts = "new_facts"
        case vibeScore = "vibe_score"
        case vibeReason = "vibe_reasoning"
        case summary = "session_summary"
        case engagementOpportunity = "engagement_opportunity"
    }

    init(
        facts: [ExtractedFact] = [],
        vibeScore: VibeScore = .medium,
        vibeReason: String = "",
        summary: String = "",
        engagementOpportunity: EngagementOpportunity? = nil
    ) {
        self.facts = facts
        self.vibeScore = vibeScore
        self.vibeReason = vibeReason
        self.summary = summary
        self.engagementOpportunity = engagementOpportunity
    }
}

struct EngagementOpportunity: Codable {
    var triggerNotification: Bool
    var notificationText: String?
    var patternDetected: String?

    enum CodingKeys: String, CodingKey {
        case triggerNotification = "trigger_notification"
        case notificationText = "notification_text"
        case patternDetected = "pattern_detected"
    }
}

struct ExtractedFact: Codable {
    var fact: String
    var category: FactCategory
}
