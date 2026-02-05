import Foundation

struct Goal: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var description: String?
    var status: GoalStatus
    var createdAt: Date
    var completedAt: Date?
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        title: String,
        description: String? = nil,
        status: GoalStatus = .active,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id.lowercased()
        self.userId = userId
        self.title = title
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }
}

enum GoalStatus: String, Codable {
    case active
    case completed
    case paused
}
