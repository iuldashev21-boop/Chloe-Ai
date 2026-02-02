import SwiftUI

extension Notification.Name {
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
}

@main
struct ChloeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .task {
                    applyInterfaceStyle(isDarkMode)
                }
                .onChange(of: isDarkMode) { _, newValue in
                    applyInterfaceStyle(newValue)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Cancel generic notifications (fallback + streak) on foreground
            // Engagement notifications survive — only cleared when user sends a message
            NotificationService.shared.cancelGenericNotifications()

        case .background:
            // Schedule fallback vibe check with last session context
            let profile = StorageService.shared.loadProfile()
            let displayName = profile?.displayName
            let lastSummary = StorageService.shared.loadLatestSummary()
            NotificationService.shared.scheduleFallbackVibeCheck(
                displayName: displayName,
                lastSummary: lastSummary
            )

            // Signal ChatViewModel to trigger pending analysis
            NotificationCenter.default.post(name: .appDidEnterBackground, object: nil)

        case .inactive:
            break

        @unknown default:
            break
        }
    }

    private func applyInterfaceStyle(_ dark: Bool) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        window.overrideUserInterfaceStyle = dark ? .dark : .light
    }
}
