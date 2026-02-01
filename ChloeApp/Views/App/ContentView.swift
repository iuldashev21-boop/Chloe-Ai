import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var onboardingComplete = false

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
        .environmentObject(authVM)
        .onAppear {
            authVM.restoreSession()
            if let profile = StorageService.shared.loadProfile() {
                onboardingComplete = profile.onboardingComplete
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingDidComplete)) { _ in
            onboardingComplete = true
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
