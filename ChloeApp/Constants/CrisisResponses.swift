import Foundation

enum CrisisType: String {
    case selfHarm = "self_harm"
    case abuse = "abuse"
    case severeMentalHealth = "severe_mental_health"
}

enum CrisisResponses {
    static let responses: [CrisisType: String] = [
        .selfHarm: """
            I hear you, and I need to step out of my usual role for a moment. What you're feeling is real, and you deserve support from someone trained to help. Please reach out:

            988 Suicide & Crisis Lifeline: Call or text 988
            Crisis Text Line: Text HOME to 741741

            You are not alone. Please talk to someone right now.
            """,

        .abuse: """
            I need to pause and be real with you. If you're in danger or being hurt, that goes beyond what I can help with — and you deserve real, immediate support.

            National Domestic Violence Hotline: 1-800-799-7233 (or text START to 88788)
            Crisis Text Line: Text HOME to 741741

            Your safety comes first. Always.
            """,

        .severeMentalHealth: """
            I care about you, and what you're describing sounds like something that needs more than a chat with me. Please reach out to someone who can really help:

            988 Suicide & Crisis Lifeline: Call or text 988
            Crisis Text Line: Text HOME to 741741
            SAMHSA Helpline: 1-800-662-4357

            There's no shame in asking for help. It's the strongest thing you can do.
            """,
    ]

    static func response(for type: CrisisType) -> String {
        return responses[type] ?? responses[.selfHarm] ?? "Please reach out to the 988 Suicide & Crisis Lifeline: call or text 988. You are not alone."
    }
}
