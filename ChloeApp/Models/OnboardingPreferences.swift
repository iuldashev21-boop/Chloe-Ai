import Foundation

struct OnboardingPreferences: Codable {
    var onboardingCompleted: Bool
    var name: String?
    var archetypeAnswers: ArchetypeAnswers?

    init(
        onboardingCompleted: Bool = false,
        name: String? = nil,
        archetypeAnswers: ArchetypeAnswers? = nil
    ) {
        self.onboardingCompleted = onboardingCompleted
        self.name = name
        self.archetypeAnswers = archetypeAnswers
    }
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
