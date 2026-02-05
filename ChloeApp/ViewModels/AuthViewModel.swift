import Foundation
import SwiftUI
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isSignUpMode = false

    private var deepLinkObserver: Any?

    init() {
        // Listen for deep link auth callbacks
        deepLinkObserver = NotificationCenter.default.addObserver(
            forName: .authDeepLinkReceived,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.restoreSession()
            }
        }
    }

    deinit {
        if let observer = deepLinkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Sign In (Email + Password)

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            self.email = session.user.email ?? email
            syncProfileFromSession(session.user)

            // Check if user is blocked after syncing profile
            if let profile = SyncDataService.shared.loadProfile(),
               checkIfBlocked(profile) {
                return
            }

            isAuthenticated = true
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign Up (Email + Password)

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
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
                successMessage = "Account created! Check your email to confirm, then come back and sign in."
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
        SyncDataService.shared.clearAll()
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

                // Check local profile for block status first (fast path)
                if let profile = SyncDataService.shared.loadProfile(),
                   checkIfBlocked(profile) {
                    return
                }

                // Set authenticated IMMEDIATELY (don't wait for sync)
                isAuthenticated = true

                // Sync in background and re-check block status after
                Task.detached { [weak self] in
                    await SyncDataService.shared.syncFromCloud()
                    // Re-check block status after sync completes
                    await MainActor.run { [weak self] in
                        if let profile = SyncDataService.shared.loadProfile() {
                            self?.checkIfBlocked(profile)
                        }
                    }
                }
            } catch {
                // No valid session — fall back to local profile check
                if let profile = SyncDataService.shared.loadProfile(),
                   !profile.email.isEmpty {
                    // Check if blocked even for local profile
                    if checkIfBlocked(profile) {
                        return
                    }
                    email = profile.email
                    isAuthenticated = true
                }
            }
        }
    }

    /// Check if profile is blocked. Returns true if blocked.
    @discardableResult
    func checkIfBlocked(_ profile: Profile) -> Bool {
        if profile.isBlocked {
            isAuthenticated = false
            errorMessage = "Your account has been suspended. Contact support@chloe.app"
            return true
        }
        return false
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
        var profile = SyncDataService.shared.loadProfile() ?? Profile()
        if profile.email.isEmpty {
            profile.email = "dev@chloe.test"
        }
        profile.onboardingComplete = true
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
        self.email = profile.email
        isAuthenticated = true
    }
    #endif

    // MARK: - Helpers

    private func syncProfileFromSession(_ user: User) {
        var profile = SyncDataService.shared.loadProfile() ?? Profile(id: user.id.uuidString)
        profile.email = user.email ?? profile.email
        profile.updatedAt = Date()
        try? SyncDataService.shared.saveProfile(profile)
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
