import Foundation

class AnalystService {
    static let shared = AnalystService()

    private let geminiService = GeminiService.shared

    private init() {}

    // MARK: - Background Analysis

    func analyze(
        messages: [Message],
        userFacts: [String] = [],
        lastSummary: String? = nil,
        currentVibe: VibeScore? = nil,
        displayName: String? = nil
    ) async throws -> AnalystResult {
        return try await geminiService.analyzeConversation(
            messages: messages,
            userFacts: userFacts,
            lastSummary: lastSummary,
            currentVibe: currentVibe,
            displayName: displayName
        )
    }

    // MARK: - Fact Merging

    func mergeNewFacts(existing: [UserFact], from result: AnalystResult, userId: String?, sourceMessageId: String?) -> [UserFact] {
        var updated = existing
        let maxFacts = 50

        for extractedFact in result.facts {
            let normalizedNew = extractedFact.fact.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let alreadyExists = updated.contains { existing in
                guard existing.isActive else { return false }
                let normalizedExisting = existing.fact.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                // Exact match or substring containment (catches LLM rephrasing)
                return normalizedExisting == normalizedNew
                    || normalizedExisting.contains(normalizedNew)
                    || normalizedNew.contains(normalizedExisting)
            }
            if !alreadyExists {
                let newFact = UserFact(
                    userId: userId,
                    fact: extractedFact.fact,
                    category: extractedFact.category,
                    sourceMessageId: sourceMessageId,
                    isActive: true
                )
                updated.append(newFact)
            }
        }

        // Cap at maxFacts — drop oldest first
        if updated.count > maxFacts {
            updated = Array(updated.suffix(maxFacts))
        }

        return updated
    }
}
