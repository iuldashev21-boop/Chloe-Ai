import Foundation

struct DailyUsage: Codable {
    var date: String
    var messageCount: Int

    init(date: String = "", messageCount: Int = 0) {
        self.date = date
        self.messageCount = messageCount
    }

    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
