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

    enum CodingKeys: String, CodingKey {
        case facts = "new_facts"
        case vibeScore = "vibe_score"
        case vibeReason = "vibe_reasoning"
        case summary = "session_summary"
    }

    init(
        facts: [ExtractedFact] = [],
        vibeScore: VibeScore = .medium,
        vibeReason: String = "",
        summary: String = ""
    ) {
        self.facts = facts
        self.vibeScore = vibeScore
        self.vibeReason = vibeReason
        self.summary = summary
    }
}

struct ExtractedFact: Codable {
    var fact: String
    var category: FactCategory
}
