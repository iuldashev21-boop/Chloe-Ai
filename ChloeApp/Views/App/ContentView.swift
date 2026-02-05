import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var onboardingComplete = false
    @State private var showNotificationPriming = false

    // TEMP: Set to true to bypass auth/onboarding for UI testing
    private let debugSkipToMain = false

    var body: some View {
        Group {
            if debugSkipToMain {
                NavigationStack {
                    SanctuaryView()
                }
            } else if !authVM.isAuthenticated {
                NavigationStack {
                    EmailLoginView()
                }
            } else if !onboardingComplete {
                NavigationStack {
                    OnboardingContainerView()
                }
            } else {
                NavigationStack {
                    SanctuaryView()
                }
            }
        }
        .background(
            LinearGradient(
                colors: [.chloeGradientStart, .chloeGradientEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .environmentObject(authVM)
        .onAppear {
            authVM.restoreSession()
            if let profile = SyncDataService.shared.loadProfile() {
                onboardingComplete = profile.onboardingComplete
            }
            // Note: syncFromCloud is now handled by restoreSession() in background
            // to avoid duplicate/concurrent syncs that caused content duplication
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingDidComplete)) { _ in
            onboardingComplete = true
            if !SyncDataService.shared.hasShownNotificationPriming() {
                showNotificationPriming = true
            }
        }
        .sheet(isPresented: $showNotificationPriming) {
            NotificationPrimingView(
                displayName: SyncDataService.shared.loadProfile()?.displayName ?? "babe",
                onEnable: {
                    SyncDataService.shared.setNotificationPrimingShown()
                    showNotificationPriming = false
                    Task {
                        let granted = await NotificationService.shared.requestPermission()
                        if !granted {
                            SyncDataService.shared.setNotificationDeniedAfterPriming()
                        }
                    }
                },
                onSkip: {
                    SyncDataService.shared.setNotificationPrimingShown()
                    showNotificationPriming = false
                }
            )
            .interactiveDismissDisabled()
        }
        .onChange(of: authVM.isAuthenticated) { _, newValue in
            if !newValue {
                onboardingComplete = false
            }
        }
    }
}

#Preview {
    ContentView()
}
