import Foundation

struct Message: Codable, Identifiable {
    let id: String
    var conversationId: String?
    var role: MessageRole
    var text: String
    var imageUri: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        conversationId: String? = nil,
        role: MessageRole,
        text: String,
        imageUri: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.text = text
        self.imageUri = imageUri
        self.createdAt = createdAt
    }
}

enum MessageRole: String, Codable {
    case user
    case chloe
}
