import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var onboardingComplete = false
    @State private var showNotificationPriming = false

    #if DEBUG
    // TEMP: Set to true to bypass auth/onboarding for UI testing
    private let debugSkipToMain = false
    #endif

    var body: some View {
        Group {
            #if DEBUG
            if debugSkipToMain {
                NavigationStack {
                    SanctuaryView()
                }
            } else {
                authFlowView
            }
            #else
            authFlowView
            #endif
        }
        .background(
            LinearGradient(
                colors: [.chloeGradientStart, .chloeGradientEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .animation(.easeInOut(duration: 0.3), value: authVM.authState)
        .animation(.easeInOut(duration: 0.3), value: onboardingComplete)
        .environmentObject(authVM)
        .onAppear {
            authVM.restoreSession()
            if let profile = SyncDataService.shared.loadProfile() {
                onboardingComplete = profile.onboardingComplete
            }
            // Note: syncFromCloud is now handled by restoreSession() in background
            // to avoid duplicate/concurrent syncs that caused content duplication
        }
        .onReceive(AppEvents.onboardingDidComplete) { _ in
            onboardingComplete = true
            if !SyncDataService.shared.hasShownNotificationPriming() {
                showNotificationPriming = true
            }
        }
        .onReceive(AppEvents.profileDidSyncFromCloud) { _ in
            // Re-check onboarding status after cloud sync completes
            if let profile = SyncDataService.shared.loadProfile() {
                onboardingComplete = profile.onboardingComplete
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
        .onChange(of: authVM.authState) { _, newState in
            if newState == .authenticated {
                // Signed IN - re-check onboarding status from profile
                if let profile = SyncDataService.shared.loadProfile() {
                    onboardingComplete = profile.onboardingComplete
                }
            } else if newState == .unauthenticated {
                // Signed OUT - reset state
                onboardingComplete = false
            }
        }
    }

    @ViewBuilder
    private var authFlowView: some View {
        switch authVM.authState {
        case .unauthenticated, .authenticating:
            NavigationStack {
                EmailLoginView()
            }
        case .awaitingEmailConfirmation:
            NavigationStack {
                EmailLoginView()
            }
        case .settingNewPassword:
            NavigationStack {
                NewPasswordView()
            }
        case .authenticated:
            if !onboardingComplete {
                NavigationStack {
                    OnboardingContainerView()
                }
            } else {
                NavigationStack {
                    SanctuaryView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
