import Foundation
import Supabase

/// DTO for Supabase feedback table
struct SupabaseFeedbackDTO: Codable {
    let id: String
    var userId: String
    var messageId: String
    var conversationId: String
    var userMessage: String
    var aiResponse: String
    var rating: String
    var reportType: String?
    var reportText: String?
    var createdAt: Date
    var reviewed: Bool
}

enum FeedbackError: LocalizedError {
    case notAuthenticated
    case emptyMessageId
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed in"
        case .emptyMessageId:
            return "Invalid message ID"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

class FeedbackService {
    static let shared = FeedbackService()

    private init() {}

    private var currentUserId: String? {
        supabase.auth.currentSession?.user.id.uuidString
    }

    /// Submit feedback for a Chloe message
    func submitFeedback(_ feedback: Feedback) async throws {
        guard let userId = currentUserId else {
            throw FeedbackError.notAuthenticated
        }

        guard !feedback.messageId.isEmpty else {
            throw FeedbackError.emptyMessageId
        }

        let dto = SupabaseFeedbackDTO(
            id: feedback.id,
            userId: userId,
            messageId: feedback.messageId,
            conversationId: feedback.conversationId,
            userMessage: feedback.userMessage,
            aiResponse: feedback.aiResponse,
            rating: feedback.rating.rawValue,
            reportType: feedback.reportType?.rawValue,
            reportText: feedback.reportText,
            createdAt: feedback.createdAt,
            reviewed: false
        )

        do {
            try await supabase.from("feedback")
                .insert(dto)
                .execute()

            // Also send to Portkey if configured
            if let traceId = PortkeyService.shared.lastTraceId {
                let portkeyRating = feedback.rating == .helpful ? "1" : "-1"
                try? await PortkeyService.shared.sendFeedback(traceId: traceId, rating: portkeyRating)
            }
        } catch {
            throw FeedbackError.networkError(error)
        }
    }

    /// Submit a report with feedback
    func submitReport(
        messageId: String,
        conversationId: String,
        userMessage: String,
        aiResponse: String,
        reportType: ReportType,
        reportText: String? = nil
    ) async throws {
        let feedback = Feedback(
            messageId: messageId,
            conversationId: conversationId,
            userMessage: userMessage,
            aiResponse: aiResponse,
            rating: .notHelpful,
            reportType: reportType,
            reportText: reportText
        )

        try await submitFeedback(feedback)
    }
}
