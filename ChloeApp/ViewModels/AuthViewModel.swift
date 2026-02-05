import Foundation
import SwiftUI
import Supabase

// MARK: - Auth State

/// Single source of truth for authentication state.
/// Replaces fragmented boolean flags with a clear state machine.
enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case awaitingEmailConfirmation(email: String)
    case settingNewPassword
    case authenticated
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var email = ""
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isSignUpMode = false

    // MARK: - Computed Properties (Backward Compatibility)

    /// Convenience accessor for views that just need to check if authenticated
    var isAuthenticated: Bool {
        authState == .authenticated
    }

    /// Convenience accessor for loading state
    var isLoading: Bool {
        authState == .authenticating
    }

    /// Bindable property for email confirmation navigation
    /// Used with .navigationDestination(isPresented:)
    var showEmailConfirmation: Bool {
        get {
            if case .awaitingEmailConfirmation = authState { return true }
            return false
        }
        set {
            if !newValue && showEmailConfirmation {
                // Dismissing email confirmation - go back to unauthenticated
                authState = .unauthenticated
            }
        }
    }

    /// Convenience accessor for pending confirmation email
    var pendingConfirmationEmail: String {
        if case .awaitingEmailConfirmation(let email) = authState { return email }
        return ""
    }

    /// Convenience accessor for new password screen
    var showNewPasswordScreen: Bool {
        authState == .settingNewPassword
    }

    private var deepLinkObserver: Any?
    private var authStateTask: Task<Void, Never>?

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

        // Listen for Supabase auth state changes
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .passwordRecovery:
                        // Supabase detected password recovery
                        UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
                        if let user = session?.user {
                            self.email = user.email ?? ""
                        }
                        self.authState = .settingNewPassword
                    case .signedIn:
                        // For password recovery, just update email - let restoreSession() handle the rest
                        // Don't remove pendingPasswordRecovery flag here; restoreSession() needs to see it
                        if let user = session?.user {
                            self.email = user.email ?? ""
                        }
                    case .signedOut:
                        self.authState = .unauthenticated
                        self.email = ""
                        UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
                    default:
                        break
                    }
                }
            }
        }
    }

    deinit {
        if let observer = deepLinkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        authStateTask?.cancel()
    }

    // MARK: - Sign In (Email + Password)

    func signIn(email: String, password: String) async {
        authState = .authenticating
        errorMessage = nil
        successMessage = nil

        // Trim whitespace from email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            let session = try await supabase.auth.signIn(
                email: trimmedEmail,
                password: password
            )
            self.email = session.user.email ?? email
            print("[SignIn] Session established for: \(session.user.email ?? "unknown")")

            // Fetch existing profile from cloud first (preserves onboardingComplete for returning users)
            if let remoteProfile = try? await SupabaseDataService.shared.fetchProfile() {
                try? StorageService.shared.saveProfile(remoteProfile)
            } else {
                // New user or fetch failed - create fresh local profile
                syncProfileFromSession(session.user)
            }

            // Check if user is blocked after syncing profile
            if let profile = SyncDataService.shared.loadProfile(),
               checkIfBlocked(profile) {
                authState = .unauthenticated
                return
            }

            authState = .authenticated

            // Notify ContentView to re-check profile on next runloop (after SwiftUI re-render completes)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .profileDidSyncFromCloud, object: nil)
            }

            // Full sync in background for other data (messages, journal, etc.)
            Task.detached {
                await SyncDataService.shared.syncFromCloud()
            }
        } catch {
            authState = .unauthenticated
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Sign Up (Email + Password)

    func signUp(email: String, password: String) async {
        authState = .authenticating
        errorMessage = nil
        successMessage = nil

        // Trim whitespace from email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            let result = try await supabase.auth.signUp(
                email: trimmedEmail,
                password: password
            )
            if let session = result.session {
                self.email = session.user.email ?? email
                syncProfileFromSession(session.user)
                authState = .authenticated
            } else {
                // Email confirmation required - navigate to confirmation screen
                authState = .awaitingEmailConfirmation(email: trimmedEmail)
            }
        } catch {
            authState = .unauthenticated
            errorMessage = friendlyError(error)
        }
    }

    // MARK: - Resend Confirmation Email

    func resendConfirmationEmail() async {
        guard case .awaitingEmailConfirmation(let email) = authState else { return }

        do {
            try await supabase.auth.resend(
                email: email,
                type: .signup
            )
        } catch {
            // Silently fail - the UI shows success anyway to prevent email enumeration
        }
    }

    func cancelEmailConfirmation() {
        authState = .unauthenticated
        isSignUpMode = false
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        // Set flag BEFORE sending reset email - we'll check this when auth callback arrives
        // This is needed because Supabase PKCE flow doesn't include type=recovery in URL
        UserDefaults.standard.set(true, forKey: "awaitingPasswordReset")
        UserDefaults.standard.synchronize()
        print("[Auth] Set awaitingPasswordReset flag")

        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "chloeapp://auth-callback")
        )
    }

    func updatePassword(_ newPassword: String) async throws {
        try await supabase.auth.update(user: UserAttributes(password: newPassword))

        // Fetch cloud profile to preserve onboardingComplete status
        if let remoteProfile = try? await SupabaseDataService.shared.fetchProfile() {
            try? StorageService.shared.saveProfile(remoteProfile)
        }

        // Password updated successfully - transition to authenticated
        authState = .authenticated

        // Notify that profile may have changed (so ContentView re-checks onboardingComplete)
        NotificationCenter.default.post(name: .profileDidSyncFromCloud, object: nil)
    }

    func handlePasswordRecovery() {
        authState = .settingNewPassword
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            try? await supabase.auth.signOut()
        }
        SyncDataService.shared.clearAll()
        authState = .unauthenticated
        email = ""
        errorMessage = nil
    }

    // MARK: - Restore Session

    func restoreSession() {
        Task {
            do {
                let session = try await supabase.auth.session
                self.email = session.user.email ?? ""

                // Check if this is a password recovery FIRST (before any profile operations)
                // This prevents overwriting the cloud profile with a blank local profile
                if UserDefaults.standard.bool(forKey: "pendingPasswordRecovery") {
                    UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
                    authState = .settingNewPassword
                    return // Don't sync profile - updatePassword() will fetch it after password change
                }

                // Normal session restore - sync profile from session
                syncProfileFromSession(session.user)

                // Check local profile for block status first (fast path)
                if let profile = SyncDataService.shared.loadProfile(),
                   checkIfBlocked(profile) {
                    authState = .unauthenticated
                    return
                }

                // Set authenticated IMMEDIATELY (don't wait for sync)
                authState = .authenticated

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
                        authState = .unauthenticated
                        return
                    }
                    email = profile.email
                    authState = .authenticated
                }
            }
        }
    }

    /// Check if profile is blocked. Returns true if blocked.
    @discardableResult
    func checkIfBlocked(_ profile: Profile) -> Bool {
        if profile.isBlocked {
            authState = .unauthenticated
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

        authState = .authenticating
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: "dev@chloe.test",
                password: devPassword
            )
            self.email = session.user.email ?? "dev@chloe.test"
            syncProfileFromSession(session.user)
            authState = .authenticated
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
        authState = .authenticated
    }
    #endif

    // MARK: - Helpers

    private func syncProfileFromSession(_ user: User) {
        let existingProfile = SyncDataService.shared.loadProfile()
        var profile = existingProfile ?? Profile(id: user.id.uuidString)
        profile.email = user.email ?? profile.email
        // Only set updatedAt if profile already existed locally (user-modified)
        // For new profiles, use distant past so cloud profile wins during sync
        if existingProfile == nil {
            profile.updatedAt = .distantPast
        }
        try? SyncDataService.shared.saveProfile(profile)
    }

    private func friendlyError(_ error: Error) -> String {
        let message = String(describing: error).lowercased()
        let localizedMessage = error.localizedDescription.lowercased()

        // Rate limiting
        if message.contains("rate") || message.contains("429") || message.contains("limit") ||
           localizedMessage.contains("rate") || localizedMessage.contains("limit") {
            return "Too many attempts. Please wait a few minutes and try again."
        }

        // Email validation errors
        if message.contains("validate email") || message.contains("invalid format") ||
           message.contains("invalid email") || localizedMessage.contains("invalid format") {
            return "Please enter a valid email address."
        }

        if localizedMessage.contains("invalid login credentials") || localizedMessage.contains("invalid_credentials") {
            return "Invalid email or password."
        }
        if localizedMessage.contains("email not confirmed") {
            return "Please confirm your email before signing in."
        }
        if localizedMessage.contains("already registered") || localizedMessage.contains("already been registered") {
            return "This email is already registered. Try signing in instead."
        }
        if localizedMessage.contains("password") && localizedMessage.contains("short") {
            return "Password must be at least 6 characters."
        }
        if localizedMessage.contains("network") || localizedMessage.contains("offline") || localizedMessage.contains("internet") {
            return "No internet connection. Please try again."
        }
        return "Something went wrong. Please try again."
    }
}
