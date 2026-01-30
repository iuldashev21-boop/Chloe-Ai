import Foundation

struct TopicCardConfig: Codable {
    var id: String
    var title: String
    var subtitle: String
    var icon: String
    var color: TopicCardColor
    var prompt: String
}

enum TopicCardColor: String, Codable {
    case pink
    case gold
    case purple
}
