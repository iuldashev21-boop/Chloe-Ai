import Foundation

struct Message: Codable, Identifiable {
    let id: String
    var conversationId: String?
    var role: MessageRole
    var text: String
    var imageUri: String?
    var createdAt: Date

    // v2 Agentic fields (nullable for backward compatibility)
    var routerMetadata: RouterMetadata?
    var contentType: MessageContentType?
    var options: [StrategyOption]?

    init(
        id: String = UUID().uuidString,
        conversationId: String? = nil,
        role: MessageRole,
        text: String,
        imageUri: String? = nil,
        createdAt: Date = Date(),
        routerMetadata: RouterMetadata? = nil,
        contentType: MessageContentType? = nil,
        options: [StrategyOption]? = nil
    ) {
        self.id = id.lowercased()
        self.conversationId = conversationId?.lowercased()
        self.role = role
        self.text = text
        self.imageUri = imageUri
        self.createdAt = createdAt
        self.routerMetadata = routerMetadata
        self.contentType = contentType
        self.options = options
    }
}

enum MessageRole: String, Codable {
    case user
    case chloe
}
