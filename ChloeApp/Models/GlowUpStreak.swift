import Foundation

struct GlowUpStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String  // "yyyy-MM-dd"

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastActiveDate: String = "") {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
    }

    static func todayKey() -> String {
        Date.todayKey
    }
}
