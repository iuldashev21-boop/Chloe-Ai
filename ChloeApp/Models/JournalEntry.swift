import Foundation

enum JournalMood: String, CaseIterable, Hashable {
    case happy, calm, grateful, anxious, sad, angry, hopeful, tired

    var emoji: String {
        switch self {
        case .happy:    return "😊"
        case .calm:     return "😌"
        case .grateful: return "🙏"
        case .anxious:  return "😰"
        case .sad:      return "😢"
        case .angry:    return "😤"
        case .hopeful:  return "🌱"
        case .tired:    return "😴"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

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
