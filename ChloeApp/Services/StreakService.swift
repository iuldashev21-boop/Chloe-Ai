import Foundation

enum StreakActivitySource {
    case chat
    case journal
}

class StreakService {
    static let shared = StreakService()

    private let storage = SyncDataService.shared

    private init() {}

    /// Record activity for streak tracking.
    /// - `chat`: Can start and extend streaks.
    /// - `journal`: Can only extend existing streaks (cannot start from zero).
    func recordActivity(source: StreakActivitySource) {
        var streak = storage.loadStreak()
        let today = GlowUpStreak.todayKey()

        // Idempotent: already recorded today
        if streak.lastActiveDate == today { return }

        let daysSinceLast = daysBetween(streak.lastActiveDate, and: today)

        if source == .journal && streak.currentStreak == 0 {
            // Journal can't start a streak from zero
            return
        }

        if daysSinceLast <= 2 {
            // Within tolerance (user can skip 1 day)
            streak.currentStreak += 1
        } else {
            // Streak broken
            if source == .journal {
                // Journal can't restart a broken streak
                return
            }
            streak.currentStreak = 1
        }

        streak.lastActiveDate = today
        streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
        storage.saveStreak(streak)

        // Reschedule streak-loss notification (reset 48h timer)
        NotificationService.shared.scheduleStreakLossNotification()
    }

    // MARK: - Helpers

    private func daysBetween(_ dateString1: String, and dateString2: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date1 = formatter.date(from: dateString1),
              let date2 = formatter.date(from: dateString2) else {
            return Int.max  // If no previous date, treat as streak broken
        }
        let components = Calendar.current.dateComponents([.day], from: date1, to: date2)
        return abs(components.day ?? Int.max)
    }
}
