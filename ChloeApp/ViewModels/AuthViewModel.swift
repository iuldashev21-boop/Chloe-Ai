import Foundation
import SwiftUI
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSignUpMode = false

    // MARK: - Sign In (Email + Password)

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            self.email = session.user.email ?? email
            syncProfileFromSession(session.user)
            isAuthenticated = true
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign Up (Email + Password)

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            if let session = result.session {
                self.email = session.user.email ?? email
                syncProfileFromSession(session.user)
                isAuthenticated = true
            } else {
                errorMessage = "Check your email to confirm your account."
            }
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            try? await supabase.auth.signOut()
        }
        StorageService.shared.clearAll()
        isAuthenticated = false
        email = ""
        errorMessage = nil
    }

    // MARK: - Restore Session

    func restoreSession() {
        Task {
            do {
                let session = try await supabase.auth.session
                self.email = session.user.email ?? ""
                syncProfileFromSession(session.user)
                isAuthenticated = true
            } catch {
                // No valid session — fall back to local profile check
                if let profile = StorageService.shared.loadProfile(),
                   !profile.email.isEmpty {
                    email = profile.email
                    isAuthenticated = true
                }
            }
        }
    }

    // MARK: - Dev Skip (DEBUG only)

    #if DEBUG
    func devSignIn() async {
        guard let devPassword = SupabaseConfig.devPassword else {
            // Fallback to local-only dev mode if no Supabase password configured
            localDevSkip()
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(
                email: "dev@chloe.test",
                password: devPassword
            )
            self.email = session.user.email ?? "dev@chloe.test"
            syncProfileFromSession(session.user)
            isAuthenticated = true
        } catch {
            // If Supabase sign-in fails (no network, user not created yet), fall back to local
            localDevSkip()
        }
    }

    private func localDevSkip() {
        var profile = StorageService.shared.loadProfile() ?? Profile()
        if profile.email.isEmpty {
            profile.email = "dev@chloe.test"
        }
        profile.onboardingComplete = true
        profile.updatedAt = Date()
        try? StorageService.shared.saveProfile(profile)
        self.email = profile.email
        isAuthenticated = true
    }
    #endif

    // MARK: - Helpers

    private func syncProfileFromSession(_ user: User) {
        var profile = StorageService.shared.loadProfile() ?? Profile(id: user.id.uuidString)
        profile.email = user.email ?? profile.email
        profile.updatedAt = Date()
        try? StorageService.shared.saveProfile(profile)
    }

    private func friendlyError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login credentials") || message.contains("invalid_credentials") {
            return "Invalid email or password."
        }
        if message.contains("email not confirmed") {
            return "Please confirm your email before signing in."
        }
        if message.contains("already registered") || message.contains("already been registered") {
            return "This email is already registered. Try signing in instead."
        }
        if message.contains("password") && message.contains("short") {
            return "Password must be at least 6 characters."
        }
        if message.contains("network") || message.contains("offline") || message.contains("internet") {
            return "No internet connection. Please try again."
        }
        return "Something went wrong. Please try again."
    }
}
