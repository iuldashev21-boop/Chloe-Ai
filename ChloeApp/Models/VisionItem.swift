import Foundation

enum VisionCategory: String, Codable, CaseIterable {
    case love
    case career
    case selfCare = "self_care"
    case travel
    case lifestyle
    case other
}

struct VisionItem: Codable, Identifiable {
    let id: String
    var userId: String?
    var imageUri: String?
    var title: String
    var category: VisionCategory
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        imageUri: String? = nil,
        title: String,
        category: VisionCategory = .other,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageUri = imageUri
        self.title = title
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
