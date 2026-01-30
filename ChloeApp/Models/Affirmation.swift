import Foundation

struct Affirmation: Codable, Identifiable {
    let id: String
    var userId: String?
    var text: String
    var date: String
    var isSaved: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        text: String,
        date: String = "",
        isSaved: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.text = text
        self.date = date
        self.isSaved = isSaved
        self.createdAt = createdAt
    }
}
