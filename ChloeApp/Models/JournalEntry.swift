import Foundation

struct JournalEntry: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var content: String
    var mood: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        title: String = "",
        content: String = "",
        mood: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.mood = mood
        self.createdAt = createdAt
    }
}

struct MoodCheckin: Codable, Identifiable {
    let id: String
    var userId: String?
    var mood: String
    var note: String?
    var date: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        mood: String,
        note: String? = nil,
        date: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.mood = mood
        self.note = note
        self.date = date
        self.createdAt = createdAt
    }
}
