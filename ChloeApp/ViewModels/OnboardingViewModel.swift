import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var quizPage: Int = 0
    @Published var preferences = OnboardingPreferences()
    @Published var isComplete = false
    @Published var nameText = ""

    private let syncDataService: SyncDataServiceProtocol

    init(syncDataService: SyncDataServiceProtocol = SyncDataService.shared) {
        self.syncDataService = syncDataService
        trackSignal("onboarding.start")
    }

    let totalSteps = 4

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    func nextStep() {
        if currentStep < totalSteps - 1 {
            trackSignal("onboarding.step\(currentStep).complete")
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
        var profile = syncDataService.loadProfile() ?? Profile()
        let trimmedName = (preferences.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        profile.displayName = trimmedName.isEmpty ? "" : trimmedName
        profile.preferences = preferences
        profile.onboardingComplete = true
        profile.updatedAt = Date()

        try? syncDataService.saveProfile(profile)
        isComplete = true
        AppEvents.onboardingDidComplete.send()
        trackSignal("onboarding.complete")
    }
}
