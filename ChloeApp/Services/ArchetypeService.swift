import Foundation

class ArchetypeService {
    static let shared = ArchetypeService()

    private init() {}

    // MARK: - Scoring Table

    private typealias ScoreMap = [ArchetypeId: Int]

    private let scoring: [String: ScoreMap] = [
        // Q1: Energy — "When you imagine your most powerful self, she..."
        "energy_a": [.siren: 2, .lover: 1],
        "energy_b": [.queen: 2, .warrior: 1],
        "energy_c": [.muse: 2, .sage: 1],
        "energy_d": [.rebel: 2, .warrior: 1],
        // Q2: Strength — "Your secret weapon is..."
        "strength_a": [.lover: 2, .muse: 1],
        "strength_b": [.sage: 2, .queen: 1],
        "strength_c": [.warrior: 2, .rebel: 1],
        "strength_d": [.siren: 2, .sage: 1],
        // Q3: Recharge — "When life gets heavy, you reset by..."
        "recharge_a": [.sage: 2, .queen: 1],
        "recharge_b": [.warrior: 2, .rebel: 1],
        "recharge_c": [.muse: 2, .lover: 1],
        "recharge_d": [.rebel: 2, .siren: 1],
        // Q4: Allure — "In your dream relationship, he's drawn to your..."
        "allure_a": [.siren: 2, .lover: 2],
        "allure_b": [.queen: 2, .warrior: 1],
        "allure_c": [.sage: 2, .muse: 1],
        "allure_d": [.rebel: 2, .siren: 1],
    ]

    // MARK: - Archetype Data

    static let archetypeData: [ArchetypeId: (label: String, briefForChloe: String)] = [
        .siren: (
            label: "The Siren",
            briefForChloe: "She oozes sensuality. The perfect blend of light and dark feminine. Her presence is a soft intoxication — every movement deliberate, pauses that make people lean in. She seduces with energy, not effort. Stillness is her weapon. She uses silence to make men decode her. She always looks like she knows a delicious secret you don't."
        ),
        .queen: (
            label: "The Queen",
            briefForChloe: "She walks in and the room shifts. She doesn't beg — she commands. Not with arrogance, but with certainty. Her allure is in her power. She creates standards and makes the world rise to meet them. Generous with those she deems worthy. Protective of her standards. When she praises you, it means something."
        ),
        .muse: (
            label: "The Muse",
            briefForChloe: "She lives in technicolour. Her emotions are her paintbrush, her life is her canvas. She's not trying to be liked — she's here to inspire, awaken, and stir something in you. Highly creative and introspective. She speaks from her soul, notices beauty in places others miss. Her presence lingers long after she's left the room."
        ),
        .lover: (
            label: "The Lover",
            briefForChloe: "She is embodied desire. Magnetic. Present. Undeniable. She doesn't just walk — she glides. She makes everything an experience. Deeply feminine because she is rooted in her pleasure. She radiates warmth, softness, and sensuality. She's in tune with her desires and unafraid to own them."
        ),
        .sage: (
            label: "The Sage",
            briefForChloe: "Depth disguised as elegance. Quiet power. Unshakeable presence. She doesn't chase attention — her presence commands it. Composed, grounded, razor-sharp. Her silence is not emptiness; it's wisdom. She is magnetic because she knows. Her discernment is her superpower — she sees through people, gently but completely."
        ),
        .rebel: (
            label: "The Rebel",
            briefForChloe: "A wildfire in a world of rules. Untamed. Unapologetic. Magnetic. She doesn't ask for permission — she IS the permission. She breaks the mold and speaks her truth effortlessly. She holds eye contact like a dare. Her raw authenticity is her sexiest trait. She refuses to play small."
        ),
        .warrior: (
            label: "The Warrior",
            briefForChloe: "Fierce, focused, and driven by purpose. She carries an aura of direction — she knows what she wants and isn't afraid to claim it. She magnetises through movement. Healthy masculine energy wrapped in divine feminine essence. Decisive but graceful. Strong but sensual. She doesn't wait to be chosen — she chooses."
        ),
    ]

    // MARK: - Classification

    func classify(answers: ArchetypeAnswers) -> UserArchetype {
        var scores: [ArchetypeId: Int] = [:]
        for id in ArchetypeId.allCases {
            scores[id] = 0
        }

        let questions: [(keyPath: KeyPath<ArchetypeAnswers, ArchetypeChoice?>, name: String)] = [
            (\.energy, "energy"),
            (\.strength, "strength"),
            (\.recharge, "recharge"),
            (\.allure, "allure"),
        ]

        for question in questions {
            guard let answer = answers[keyPath: question.keyPath] else { continue }
            let key = "\(question.name)_\(answer.rawValue)"
            if let questionScores = scoring[key] {
                for (archetype, score) in questionScores {
                    scores[archetype, default: 0] += score
                }
            }
        }

        let sorted = ArchetypeId.allCases.sorted { scores[$0, default: 0] > scores[$1, default: 0] }

        guard sorted.count >= 3 else {
            let fallback = sorted.first ?? .siren
            return UserArchetype(primary: fallback, secondary: fallback, label: fallback.rawValue.capitalized, blend: fallback.rawValue.capitalized, description: "")
        }

        let primary = sorted[0]
        let secondary = sorted[1] == primary ? sorted[2] : sorted[1]

        guard let primaryData = Self.archetypeData[primary],
              let secondaryData = Self.archetypeData[secondary] else {
            return UserArchetype(
                primary: primary,
                secondary: secondary,
                label: primary.rawValue.capitalized,
                blend: "\(primary.rawValue.capitalized)-\(secondary.rawValue.capitalized)",
                description: ""
            )
        }

        return UserArchetype(
            primary: primary,
            secondary: secondary,
            label: primaryData.label,
            blend: "\(primary.rawValue.capitalized)-\(secondary.rawValue.capitalized)",
            description: "Primary: \(primaryData.label) — \(primaryData.briefForChloe)\n\nSecondary: \(secondaryData.label) — \(secondaryData.briefForChloe)"
        )
    }
}

// MARK: - Protocol Conformance

extension ArchetypeService: ArchetypeServiceProtocol {}
