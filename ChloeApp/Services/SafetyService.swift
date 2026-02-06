import Foundation

struct SafetyCheckResult {
    var blocked: Bool
    var crisisType: CrisisType?
}

class SafetyService {
    static let shared = SafetyService()

    // MARK: - Pre-compiled Regex Patterns

    private let compiledSelfHarm: [NSRegularExpression]
    private let compiledAbuse: [NSRegularExpression]
    private let compiledSevereMentalHealth: [NSRegularExpression]
    private let compiledSoftSpiral: [NSRegularExpression]

    private init() {
        compiledSelfHarm = Self.compile([
            #"\b(kill\s*(my\s*self|myself))\b"#,
            #"\b(want\s*to\s*die)\b"#,
            #"\b(end\s*(my\s*life|it\s*all))\b"#,
            #"\b(sui?cid(e|al))\b"#,
            #"\b(don'?t\s*want\s*to\s*(be\s*here|live|exist))\b"#,
            #"\b(hurt\s*myself)\b"#,
            #"\b(self[\s\-]?harm)\b"#,
            #"\b(cutting\s*myself)\b"#,
            #"\b(take\s*my\s*(own\s*)?life)\b"#,
            #"\b(better\s*off\s*(dead|without\s*me))\b"#,
            #"\b(no\s*reason\s*to\s*live)\b"#,
            #"\b(want\s*to\s*hurt\s*myself)\b"#,
            #"\b(overdose)\b"#,
        ])

        compiledAbuse = Self.compile([
            #"\b(he\s*(hits|beat[s]?|punch|slap|choke|strangle)[s]?\s*me)\b"#,
            #"\b(physically\s*abus(e[sd]?|ing))\b"#,
            #"\b(domestic\s*(violence|abuse))\b"#,
            #"\b(he\s*threat(en)?s?\s*to\s*(kill|hurt))\b"#,
            #"\b(force[sd]?\s*me\s*to)\b"#,
            #"\b(r[a]?ped?\s*me)\b"#,
            #"\b(sexual(ly)?\s*assault)\b"#,
            #"\b(afraid\s*(he('?ll| will)\s*(hurt|kill)))\b"#,
        ])

        compiledSevereMentalHealth = Self.compile([
            #"\b(hear(ing)?\s*voices)\b"#,
            #"\b(seeing\s*things\s*(that\s*aren'?t|no\s*one\s*else))\b"#,
            #"\b(psycho(sis|tic))\b"#,
            #"\b(haven'?t\s*(eaten|slept)\s*(in|for)\s*days)\b"#,
            #"\b(can'?t\s*stop\s*crying\s*(for\s*)?(days|hours))\b"#,
            #"\b(complete(ly)?\s*dissociat)\b"#,
        ])

        compiledSoftSpiral = Self.compile([
            #"\bfeeling\s+numb\b"#,
            #"\bfeeling\s+hollow\b"#,
            #"\bfeeling\s+nothing\b"#,
            #"\bempty\s+inside\b"#,
            #"\bcan'?t\s+get\s+out\s+of\s+bed\b"#,
            #"\bcan'?t\s+move\b"#,
            #"\bcan'?t\s+function\b"#,
            #"\beverything\s+feels\s+heavy\b"#,
            #"\bjust\s+existing\b"#,
            #"\bgoing\s+through\s+the\s+motions\b"#,
            #"\bshutting\s+down\b"#,
            #"\bdisconnected\s+from\s+everything\b"#,
            #"\bdisconnected\s+from\s+myself\b"#,
            #"\bdon'?t\s+feel\s+like\s+myself\b"#,
            #"\bcan'?t\s+feel\s+anything\b"#,
            #"\bemotionally\s+drained\b"#,
            #"\bemotionally\s+exhausted\b"#,
            #"\bemotionally\s+flat\b"#,
            #"\brunning\s+on\s+autopilot\b"#,
            #"\brunning\s+on\s+empty\b"#,
        ])
    }

    private static func compile(_ patterns: [String]) -> [NSRegularExpression] {
        patterns.compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }
    }

    // MARK: - Public API

    func checkSoftSpiral(message: String) -> Bool {
        return matchesAny(compiled: compiledSoftSpiral, in: message)
    }

    func checkSafety(message: String) -> SafetyCheckResult {
        if matchesAny(compiled: compiledSelfHarm, in: message) {
            return SafetyCheckResult(blocked: true, crisisType: .selfHarm)
        }

        if matchesAny(compiled: compiledAbuse, in: message) {
            return SafetyCheckResult(blocked: true, crisisType: .abuse)
        }

        if matchesAny(compiled: compiledSevereMentalHealth, in: message) {
            return SafetyCheckResult(blocked: true, crisisType: .severeMentalHealth)
        }

        return SafetyCheckResult(blocked: false, crisisType: nil)
    }

    func getCrisisResponse(for crisisType: CrisisType) -> String {
        return CrisisResponses.response(for: crisisType)
    }

    // MARK: - Private

    private func matchesAny(compiled: [NSRegularExpression], in text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return compiled.contains { $0.firstMatch(in: text, range: range) != nil }
    }
}
