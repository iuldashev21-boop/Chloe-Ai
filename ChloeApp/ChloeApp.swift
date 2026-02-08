import SwiftUI
import UserNotifications
import Supabase
import TelemetryDeck

/// Safe wrapper for TelemetryDeck signals — no-ops when TelemetryDeck isn't initialized (e.g. in tests).
private var _telemetryInitialized = false

func trackSignal(_ name: String, parameters: [String: String] = [:]) {
    guard _telemetryInitialized else { return }
    TelemetryDeck.signal(name, parameters: parameters)
}

@main
struct ChloeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        UITestSupport.setupTestEnvironment()
        #endif

        // Initialize TelemetryDeck analytics (privacy-first, no PII collected)
        let telemetryAppID = Bundle.main.infoDictionary?["TELEMETRY_DECK_APP_ID"] as? String ?? ""
        if !telemetryAppID.isEmpty && telemetryAppID != "YOUR_TELEMETRY_DECK_APP_ID" {
            let config = TelemetryDeck.Config(appID: telemetryAppID)
            TelemetryDeck.initialize(config: config)
            _telemetryInitialized = true
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .background(
                    LinearGradient(
                        colors: [.chloeGradientStart, .chloeGradientEnd],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
                .onAppear {
                    // Set window background synchronously on appear (not async)
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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    handleMemoryWarning()
                }
        }
    }

    private func handleMemoryWarning() {
        #if DEBUG
        print("[ChloeApp] Memory warning received — clearing caches")
        #endif
        // Clear StorageService in-memory caches
        StorageService.shared.clearCaches()
        // Clear URLCache for any network-loaded images
        URLCache.shared.removeAllCachedResponses()
        trackSignal("app.memoryWarning")
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

            // Note: ChatViewModel now observes scenePhase directly via SanctuaryView

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
        // Set window background to match chloeGradientStart (the top of the gradient)
        // The gradient extends into safe areas, so this is just a fallback
        // Light: #FFF8F5, Dark: #1A1517 (must match Colors.swift chloeGradientStart)
        window.backgroundColor = dark ? UIColor(hex: "#1A1517") : UIColor(hex: "#FFF8F5")
        // Also set the root view's background
        window.rootViewController?.view.backgroundColor = window.backgroundColor
    }

    private func handleDeepLink(_ url: URL) {
        #if DEBUG
        print("[DeepLink] Received URL: \(url.absoluteString)")
        #endif

        // Guard against malformed URLs — must have a scheme and host/path to be valid
        guard url.scheme != nil, !url.absoluteString.isEmpty,
              url.host != nil || url.path.count > 1 else {
            #if DEBUG
            print("[DeepLink] Ignoring malformed URL")
            #endif
            return
        }

        // Check if user was awaiting password reset (flag set when they requested reset)
        // This is more reliable than parsing URL since Supabase PKCE doesn't include type=recovery
        let awaitingReset = UserDefaults.standard.bool(forKey: "awaitingPasswordReset")
        #if DEBUG
        print("[DeepLink] Awaiting password reset: \(awaitingReset)")
        #endif

        if awaitingReset {
            // Transfer the flag to pendingPasswordRecovery for AuthViewModel to pick up
            UserDefaults.standard.set(true, forKey: "pendingPasswordRecovery")
            UserDefaults.standard.removeObject(forKey: "awaitingPasswordReset")
            #if DEBUG
            print("[DeepLink] Password recovery flag SET (from awaitingReset)")
            #endif
        }

        Task {
            do {
                try await supabase.auth.session(from: url)
                #if DEBUG
                print("[DeepLink] Session established successfully")
                #endif
                // Signal AuthViewModel to restore session after deep link auth
                AppEvents.authDeepLinkReceived.send()
            } catch {
                #if DEBUG
                print("[DeepLink] Auth callback failed: \(error)")
                #endif
                // Silent fail for users — deep link auth errors don't need user-facing alerts
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
