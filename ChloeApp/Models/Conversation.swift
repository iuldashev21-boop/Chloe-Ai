import Foundation

struct Conversation: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var starred: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        title: String = "New Conversation",
        starred: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.starred = starred
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
