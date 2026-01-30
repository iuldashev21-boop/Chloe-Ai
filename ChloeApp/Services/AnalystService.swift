import Foundation

class AnalystService {
    static let shared = AnalystService()

    private let geminiService = GeminiService.shared

    private init() {}

    // MARK: - Background Analysis

    func analyze(messages: [Message]) async throws -> AnalystResult {
        return try await geminiService.analyzeConversation(messages: messages)
    }

    // MARK: - Fact Merging

    func mergeNewFacts(existing: [UserFact], from result: AnalystResult, userId: String?, sourceMessageId: String?) -> [UserFact] {
        var updated = existing

        for extractedFact in result.facts {
            let alreadyExists = existing.contains { $0.fact == extractedFact.fact && $0.isActive }
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

        return updated
    }
}
