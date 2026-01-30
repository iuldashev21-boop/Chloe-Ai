import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var onboardingComplete = false

    var body: some View {
        Group {
            if !authVM.isAuthenticated {
                NavigationStack {
                    WelcomeView()
                }
            } else if !onboardingComplete {
                NavigationStack {
                    OnboardingContainerView()
                }
            } else {
                MainTabView()
            }
        }
        .environmentObject(authVM)
        .onAppear {
            // Check if profile exists and onboarding is done
            if let profile = StorageService.shared.loadProfile() {
                onboardingComplete = profile.onboardingComplete
            }
        }
    }
}

#Preview {
    ContentView()
}
