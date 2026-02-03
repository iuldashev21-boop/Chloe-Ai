import Foundation

enum FeedbackRating: String, Codable {
    case helpful
    case notHelpful = "not_helpful"
}

enum ReportType: String, Codable, CaseIterable {
    case harmful
    case incorrect
    case unhelpful
    case other

    var displayName: String {
        switch self {
        case .harmful: return "Harmful"
        case .incorrect: return "Incorrect"
        case .unhelpful: return "Unhelpful"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .harmful: return "Could cause harm or is unsafe"
        case .incorrect: return "Information is factually wrong"
        case .unhelpful: return "Doesn't address my question"
        case .other: return "Something else is wrong"
        }
    }
}

struct Feedback: Codable, Identifiable {
    var id: String = UUID().uuidString
    let messageId: String
    let conversationId: String
    let userMessage: String
    let aiResponse: String
    let rating: FeedbackRating
    var reportType: ReportType?
    var reportText: String?
    var createdAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        messageId: String,
        conversationId: String,
        userMessage: String,
        aiResponse: String,
        rating: FeedbackRating,
        reportType: ReportType? = nil,
        reportText: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.messageId = messageId
        self.conversationId = conversationId
        self.userMessage = userMessage
        self.aiResponse = aiResponse
        self.rating = rating
        self.reportType = reportType
        self.reportText = reportText
        self.createdAt = createdAt
    }
}

/// Tracks feedback state for a message in the UI
enum MessageFeedbackState: Equatable {
    case none
    case helpful
    case notHelpful
    case reported
}
