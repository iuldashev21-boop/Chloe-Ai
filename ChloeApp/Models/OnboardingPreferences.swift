import Foundation

struct OnboardingPreferences: Codable {
    var onboardingCompleted: Bool
    var name: String?
    var relationshipStatus: [RelationshipStatus]?
    var primaryGoal: [PrimaryGoal]?
    var coreDesire: [CoreDesire]?
    var painPoint: [PainPoint]?
    var vibeScore: VibeScore?
    var archetypeAnswers: ArchetypeAnswers?

    init(
        onboardingCompleted: Bool = false,
        name: String? = nil,
        relationshipStatus: [RelationshipStatus]? = nil,
        primaryGoal: [PrimaryGoal]? = nil,
        coreDesire: [CoreDesire]? = nil,
        painPoint: [PainPoint]? = nil,
        vibeScore: VibeScore? = nil,
        archetypeAnswers: ArchetypeAnswers? = nil
    ) {
        self.onboardingCompleted = onboardingCompleted
        self.name = name
        self.relationshipStatus = relationshipStatus
        self.primaryGoal = primaryGoal
        self.coreDesire = coreDesire
        self.painPoint = painPoint
        self.vibeScore = vibeScore
        self.archetypeAnswers = archetypeAnswers
    }
}

enum RelationshipStatus: String, Codable, CaseIterable {
    case singleExploring = "single_exploring"
    case datingNew = "dating_new"
    case inRelationship = "in_relationship"
    case complicated = "complicated"
    case breakupRecovery = "breakup_recovery"
    case happilyTaken = "happily_taken"
}

enum PrimaryGoal: String, Codable, CaseIterable {
    case findingPerson = "finding_person"
    case understandingMen = "understanding_men"
    case buildingConfidence = "building_confidence"
    case healingBreakup = "healing_breakup"
    case improvingRelationship = "improving_relationship"
    case feminineEnergy = "feminine_energy"
}

enum CoreDesire: String, Codable, CaseIterable {
    case marriage = "marriage"
    case detachment = "detachment"
    case glowUp = "glow_up"
    case highValueDating = "high_value_dating"
    case selfMastery = "self_mastery"
}

enum PainPoint: String, Codable, CaseIterable {
    case anxiousAttachment = "anxious_attachment"
    case peoplePleasing = "people_pleasing"
    case lowSelfWorth = "low_self_worth"
    case fearOfAbandonment = "fear_of_abandonment"
    case codependency = "codependency"
    case settling = "settling"
}

enum VibeScore: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

struct ArchetypeAnswers: Codable {
    var energy: ArchetypeChoice?
    var strength: ArchetypeChoice?
    var recharge: ArchetypeChoice?
    var allure: ArchetypeChoice?
}

enum ArchetypeChoice: String, Codable, CaseIterable {
    case a, b, c, d
}
