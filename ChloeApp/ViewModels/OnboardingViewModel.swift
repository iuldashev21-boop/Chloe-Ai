import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var preferences = OnboardingPreferences()
    @Published var isComplete = false

    let totalSteps = 9

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
        var profile = StorageService.shared.loadProfile() ?? Profile()
        profile.displayName = preferences.name ?? ""
        profile.preferences = preferences
        profile.onboardingComplete = true
        profile.updatedAt = Date()

        // Save initial vibe score if set
        if let vibe = preferences.vibeScore {
            StorageService.shared.saveLatestVibe(vibe)
        }

        try? StorageService.shared.saveProfile(profile)
        isComplete = true
    }
}
