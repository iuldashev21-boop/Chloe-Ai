import SwiftUI
import UserNotifications
import Supabase

extension Notification.Name {
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    static let authDeepLinkReceived = Notification.Name("authDeepLinkReceived")
}

@main
struct ChloeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        UITestSupport.setupTestEnvironment()
        #endif
    }

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
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Cancel generic notifications (fallback + streak) on foreground
            // Engagement notifications survive — only cleared when user sends a message
            NotificationService.shared.cancelGenericNotifications()

            // Schedule tomorrow's affirmation if not already scheduled
            Task {
                await scheduleAffirmationIfNeeded()
            }

        case .background:
            // Schedule fallback vibe check with last session context
            let profile = SyncDataService.shared.loadProfile()
            let displayName = profile?.displayName
            let lastSummary = SyncDataService.shared.loadLatestSummary()
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
        // Set window background to match app theme (fixes white footer in safe area)
        window.backgroundColor = dark ? UIColor(hex: "#1A1517") : UIColor(hex: "#FEEAE2")
    }

    private func handleDeepLink(_ url: URL) {
        // Handle Supabase auth callback (email confirmation)
        Task {
            do {
                try await supabase.auth.session(from: url)
                // Post notification so AuthViewModel can refresh
                NotificationCenter.default.post(name: .authDeepLinkReceived, object: nil)
            } catch {
                // Silently fail - user can manually sign in
                print("[DeepLink] Auth callback failed: \(error)")
            }
        }
    }

    private func scheduleAffirmationIfNeeded() async {
        // Check if already scheduled
        guard await !NotificationService.shared.hasScheduledAffirmation() else { return }

        // Check notification permission
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        // Load user context
        let profile = SyncDataService.shared.loadProfile()
        let displayName = profile?.displayName ?? "babe"
        let preferences = profile?.preferences

        // Compute archetype from answers if available
        var archetype: UserArchetype?
        if let answers = preferences?.archetypeAnswers {
            archetype = ArchetypeService.shared.classify(answers: answers)
        }

        // Generate affirmation via Gemini
        do {
            let affirmation = try await GeminiService.shared.generateAffirmation(
                displayName: displayName,
                preferences: preferences,
                archetype: archetype
            )
            NotificationService.shared.scheduleAffirmationNotification(text: affirmation)
        } catch {
            // Silent fail - will retry next app open
        }
    }
}
