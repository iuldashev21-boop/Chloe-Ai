import Foundation

struct Goal: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var description: String?
    var status: GoalStatus
    var createdAt: Date
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        title: String,
        description: String? = nil,
        status: GoalStatus = .active,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

enum GoalStatus: String, Codable {
    case active
    case completed
    case paused
}
