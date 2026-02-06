import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let storage = SyncDataService.shared

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Check if notifications are currently authorized. Returns false if denied or not determined.
    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Engagement Notifications (analyst-driven, no weekly cap)

    func scheduleEngagementNotification(text: String) {
        // Check permission before scheduling to avoid silent failures
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized, let self else { return }

            let content = UNMutableNotificationContent()
            content.title = "Chloe"
            content.body = text
            content.sound = .default

            // Schedule 4 hours from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 3600, repeats: false)
            let request = UNNotificationRequest(
                identifier: "engagement_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            self.center.add(request)
        }
    }

    // MARK: - Fallback Vibe Check (generic, capped at 3/week)

    func scheduleFallbackVibeCheck(displayName: String?, lastSummary: String?) {
        guard storage.canSendGenericNotification() else { return }

        // Check permission before scheduling to avoid silent failures
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized, let self else { return }

            let content = UNMutableNotificationContent()
            content.title = "Chloe"
            content.sound = .default

            let name = displayName ?? "babe"
            if let summary = lastSummary, !summary.isEmpty {
                // Contextual message from last session
                content.body = "Hey \(name), how did that go? \(summary)"
            } else {
                // Generic fallback
                let fallbacks = [
                    "Hey \(name), just checking in. How are you feeling today?",
                    "Hey \(name), I was thinking about you. Come talk to me when you're ready.",
                    "Hey \(name), quick vibe check -- how's your energy today?",
                ]
                content.body = fallbacks.randomElement() ?? fallbacks[0]
            }

            // Schedule 24-48 hours from now (randomized)
            let delay = Double.random(in: 24 * 3600 ... 48 * 3600)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: "fallback_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )

            self.center.add(request)
            self.storage.incrementGenericNotificationCount()
        }
    }

    // MARK: - Streak Loss Warning (generic, capped at 3/week)

    func scheduleStreakLossNotification() {
        guard storage.canSendGenericNotification() else { return }

        // Check permission before scheduling to avoid silent failures
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized, let self else { return }

            // Remove any existing streak notification before scheduling a new one
            self.center.removePendingNotificationRequests(withIdentifiers: ["streak_warning"])

            let content = UNMutableNotificationContent()
            content.title = "Chloe"
            content.body = "Your glow-up streak is about to expire! Come say hi before it resets."
            content.sound = .default

            // 48 hours from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 3600, repeats: false)
            let request = UNNotificationRequest(
                identifier: "streak_warning",
                content: content,
                trigger: trigger
            )

            self.center.add(request)
            self.storage.incrementGenericNotificationCount()
        }
    }

    // MARK: - Daily Affirmation

    /// Check if tomorrow's affirmation is already scheduled
    func hasScheduledAffirmation() async -> Bool {
        let requests = await center.pendingNotificationRequests()
        return requests.contains { $0.identifier.hasPrefix("affirmation_") }
    }

    /// Schedule affirmation for random time between 7-9 AM tomorrow
    func scheduleAffirmationNotification(text: String) {
        // Check permission before scheduling to avoid silent failures
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized, let self else { return }

            let content = UNMutableNotificationContent()
            content.title = "Chloe"
            content.body = text
            content.sound = .default

            // Random hour between 7-9, random minute
            let hour = Int.random(in: 7...8)
            let minute = Int.random(in: 0...59)

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            // Next occurrence of this time (tomorrow if already past today)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let identifier = "affirmation_\(UUID().uuidString)"
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            self.center.add(request)
        }
    }

    // MARK: - Cancellation

    /// Cancel only generic notifications (fallback + streak). Called when app enters foreground.
    func cancelGenericNotifications() {
        center.getPendingNotificationRequests { requests in
            let genericIds = requests
                .filter { $0.identifier.hasPrefix("fallback_") || $0.identifier == "streak_warning" }
                .map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: genericIds)
        }
    }

    /// Cancel engagement notifications. Called when user sends a new message (re-engagement).
    func cancelEngagementNotifications() {
        center.getPendingNotificationRequests { requests in
            let engagementIds = requests
                .filter { $0.identifier.hasPrefix("engagement_") }
                .map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: engagementIds)
        }
    }
}
