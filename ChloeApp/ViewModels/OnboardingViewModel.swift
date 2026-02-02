import Foundation
import SwiftUI

extension Notification.Name {
    static let onboardingDidComplete = Notification.Name("onboardingDidComplete")
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var quizPage: Int = 0
    @Published var preferences = OnboardingPreferences()
    @Published var isComplete = false
    @Published var nameText = ""

    let totalSteps = 4

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            completeOnboarding()
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func completeOnboarding() {
        preferences.onboardingCompleted = true

        // Save profile with preferences
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        profile.displayName = preferences.name ?? ""
        profile.preferences = preferences
        profile.onboardingComplete = true
        profile.updatedAt = Date()

        try? SyncDataService.shared.saveProfile(profile)
        isComplete = true
        NotificationCenter.default.post(name: .onboardingDidComplete, object: nil)
    }
}
