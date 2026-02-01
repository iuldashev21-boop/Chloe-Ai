import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn(email: String) async {
        isLoading = true
        defer { isLoading = false }

        self.email = email

        // Persist email to profile
        var profile = StorageService.shared.loadProfile() ?? Profile()
        profile.email = email
        profile.updatedAt = Date()
        try? StorageService.shared.saveProfile(profile)

        isAuthenticated = true
    }

    func signOut() {
        StorageService.shared.clearAll()
        isAuthenticated = false
        email = ""
    }

    func restoreSession() {
        if let profile = StorageService.shared.loadProfile(),
           !profile.email.isEmpty {
            email = profile.email
            isAuthenticated = true
        }
    }
}
