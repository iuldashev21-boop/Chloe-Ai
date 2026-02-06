import Foundation
import SwiftUI
import Supabase
import Combine

// MARK: - AuthService

/// Pure authentication service — owns Supabase auth calls, session management,
/// and auth state. No UI form fields (those live in AuthViewModel).
///
/// AuthViewModel delegates all actual auth operations here and handles
/// UI concerns (loading states, error formatting, form fields) on its own.
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var authState: AuthState = .unauthenticated
    @Published var email = ""
    @Published var errorMessage: String?

    // MARK: - Computed Properties (required by AuthServiceProtocol)

    var isAuthenticated: Bool {
        authState == .authenticated
    }

    var isLoading: Bool {
        authState == .authenticating
    }

    private let storageService: StorageServiceProtocol
    private let syncDataService: SyncDataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var authStateTask: Task<Void, Never>?

    init(
        storageService: StorageServiceProtocol = StorageService.shared,
        syncDataService: SyncDataServiceProtocol = SyncDataService.shared
    ) {
        self.storageService = storageService
        self.syncDataService = syncDataService

        // Listen for deep link auth callbacks via Combine
        AppEvents.authDeepLinkReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.restoreSession()
            }
            .store(in: &cancellables)

        // Listen for Supabase auth state changes
        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    AuthLogger.event("Supabase event", detail: "\(event)")
                    switch event {
                    case .passwordRecovery:
                        let oldState = self.authState
                        UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
                        if let user = session?.user {
                            self.email = user.email ?? ""
                        }
                        self.authState = .settingNewPassword
                        AuthLogger.stateChange(from: oldState, to: .settingNewPassword, reason: "Supabase passwordRecovery event")
                    case .signedIn:
                        if let user = session?.user {
                            self.email = user.email ?? ""
                            AuthLogger.event("signedIn event", detail: "email=\(user.email ?? "nil"), currentState=\(self.authState.displayName)")
                        }
                        // If we were awaiting email confirmation, the user just confirmed — transition to authenticated
                        if case .awaitingEmailConfirmation = self.authState {
                            let oldState = self.authState
                            if let user = session?.user {
                                self.syncProfileFromSession(user)
                            }
                            self.authState = .authenticated
                            AuthLogger.stateChange(from: oldState, to: .authenticated, reason: "email confirmed via signedIn event")
                        }
                        // For other states (.authenticating, .unauthenticated), let signIn()/restoreSession() handle it
                    case .signedOut:
                        let oldState = self.authState
                        self.authState = .unauthenticated
                        self.email = ""
                        UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
                        AuthLogger.stateChange(from: oldState, to: .unauthenticated, reason: "Supabase signedOut event")
                    default:
                        break
                    }
                }
            }
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Sign In (Email + Password)

    func signIn(email: String, password: String) async {
        AuthLogger.stateChange(from: authState, to: .authenticating, reason: "signIn started")
        authState = .authenticating
        errorMessage = nil

        // Trim whitespace from email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            let session = try await supabase.auth.signIn(
                email: trimmedEmail,
                password: password
            )
            self.email = session.user.email ?? email
            AuthLogger.event("Session established", detail: "email=\(session.user.email ?? "unknown")")

            // Fetch existing profile from cloud first (preserves onboardingComplete for returning users)
            if let remoteProfile = try? await SupabaseDataService.shared.fetchProfile() {
                try? storageService.saveProfile(remoteProfile)
                AuthLogger.event("Profile fetched from cloud", detail: "onboardingComplete=\(remoteProfile.onboardingComplete)")
            } else {
                // New user or fetch failed - create fresh local profile
                syncProfileFromSession(session.user)
                AuthLogger.event("Created local profile", detail: "new user or fetch failed")
            }

            // Check if user is blocked after syncing profile
            if let profile = syncDataService.loadProfile(),
               checkIfBlocked(profile) {
                AuthLogger.stateChange(from: .authenticating, to: .unauthenticated, reason: "user blocked")
                authState = .unauthenticated
                return
            }

            AuthLogger.stateChange(from: .authenticating, to: .authenticated, reason: "signIn succeeded")
            authState = .authenticated
            trackSignal("auth.signIn.success")

            // Full sync in background for other data (messages, journal, etc.)
            // syncFromCloud() sends AppEvents.profileDidSyncFromCloud when it completes.
            Task.detached { [syncDataService] in
                await syncDataService.syncFromCloud()
            }
        } catch {
            AuthLogger.error("signIn failed", error: error)
            authState = .unauthenticated
            errorMessage = friendlyError(error)
            trackSignal("auth.signIn.error", parameters: ["errorType": classifyAuthError(error)])
        }
    }

    // MARK: - Sign Up (Email + Password)

    func signUp(email: String, password: String) async {
        AuthLogger.stateChange(from: authState, to: .authenticating, reason: "signUp started")
        authState = .authenticating
        errorMessage = nil

        // Trim whitespace from email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            let result = try await supabase.auth.signUp(
                email: trimmedEmail,
                password: password,
                redirectTo: URL(string: "chloeapp://auth-callback")
            )
            if let session = result.session {
                self.email = session.user.email ?? email
                syncProfileFromSession(session.user)
                AuthLogger.stateChange(from: .authenticating, to: .authenticated, reason: "signUp succeeded (no email confirmation)")
                authState = .authenticated
                trackSignal("auth.signUp.success")
            } else {
                // Email confirmation required - navigate to confirmation screen
                let newState = AuthState.awaitingEmailConfirmation(email: trimmedEmail)
                AuthLogger.stateChange(from: .authenticating, to: newState, reason: "email confirmation required")
                authState = newState
                trackSignal("auth.signUp.awaitingConfirmation")
            }
        } catch {
            AuthLogger.error("signUp failed", error: error)
            authState = .unauthenticated
            errorMessage = friendlyError(error)
            trackSignal("auth.signUp.error", parameters: ["errorType": classifyAuthError(error)])
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async {
        AuthLogger.stateChange(from: authState, to: .authenticating, reason: "Apple sign-in started")
        authState = .authenticating
        errorMessage = nil

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            self.email = session.user.email ?? ""
            AuthLogger.event("Apple sign-in session established", detail: "email=\(session.user.email ?? "unknown")")

            // Fetch existing profile from cloud first (returning user)
            if let remoteProfile = try? await SupabaseDataService.shared.fetchProfile() {
                try? storageService.saveProfile(remoteProfile)
                AuthLogger.event("Profile fetched from cloud", detail: "onboardingComplete=\(remoteProfile.onboardingComplete)")
            } else {
                // New Apple sign-in user — create profile with name from Apple
                var profile = Profile(id: session.user.id.uuidString)
                profile.email = session.user.email ?? ""
                if let fullName = fullName {
                    let displayName = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    if !displayName.isEmpty {
                        profile.displayName = displayName
                    }
                }
                profile.updatedAt = .distantPast
                try? syncDataService.saveProfile(profile)
                AuthLogger.event("Created profile from Apple sign-in", detail: "name=\(profile.displayName)")
            }

            // Check if user is blocked
            if let profile = syncDataService.loadProfile(),
               checkIfBlocked(profile) {
                AuthLogger.stateChange(from: .authenticating, to: .unauthenticated, reason: "user blocked")
                authState = .unauthenticated
                return
            }

            AuthLogger.stateChange(from: .authenticating, to: .authenticated, reason: "Apple sign-in succeeded")
            authState = .authenticated
            trackSignal("auth.signInWithApple.success")

            // Full sync in background
            Task.detached { [syncDataService] in
                await syncDataService.syncFromCloud()
            }
        } catch {
            AuthLogger.error("Apple sign-in failed", error: error)
            authState = .unauthenticated
            errorMessage = friendlyError(error)
            trackSignal("auth.signInWithApple.error", parameters: ["errorType": classifyAuthError(error)])
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
        AuthLogger.stateChange(from: authState, to: .unauthenticated, reason: "email confirmation cancelled")
        authState = .unauthenticated
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        // Set flag BEFORE sending reset email - we'll check this when auth callback arrives
        // This is needed because Supabase PKCE flow doesn't include type=recovery in URL
        UserDefaults.standard.set(true, forKey: "awaitingPasswordReset")
        UserDefaults.standard.synchronize()
        AuthLogger.flag("awaitingPasswordReset", value: true)

        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "chloeapp://auth-callback")
        )
        AuthLogger.event("Password reset email sent", detail: "email=\(email)")
        trackSignal("auth.passwordReset.requested")
    }

    func updatePassword(_ newPassword: String) async throws {
        AuthLogger.event("updatePassword started")
        try await supabase.auth.update(user: UserAttributes(password: newPassword))

        // Fetch cloud profile to preserve onboardingComplete status
        if let remoteProfile = try? await SupabaseDataService.shared.fetchProfile() {
            try? storageService.saveProfile(remoteProfile)
            AuthLogger.event("Profile fetched after password update", detail: "onboardingComplete=\(remoteProfile.onboardingComplete)")
        }

        // Password updated successfully - transition to authenticated
        AuthLogger.stateChange(from: authState, to: .authenticated, reason: "password updated")
        authState = .authenticated

        // Sync all user data from cloud (conversations, messages, goals, journal, vision board)
        // syncFromCloud() posts .profileDidSyncFromCloud when it completes.
        AuthLogger.event("Starting full data sync after password update")
        Task {
            await syncDataService.syncFromCloud()
            AuthLogger.event("Full data sync completed after password update")
        }
    }

    func handlePasswordRecovery() {
        AuthLogger.stateChange(from: authState, to: .settingNewPassword, reason: "handlePasswordRecovery called")
        authState = .settingNewPassword
    }

    // MARK: - Sign Out

    func signOut() {
        AuthLogger.stateChange(from: authState, to: .unauthenticated, reason: "signOut called")
        trackSignal("auth.signOut")
        Task {
            try? await supabase.auth.signOut()
        }
        syncDataService.clearAll()
        // Clear all auth-related UserDefaults flags
        UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
        UserDefaults.standard.removeObject(forKey: "awaitingPasswordReset")
        authState = .unauthenticated
        email = ""
        errorMessage = nil
    }

    // MARK: - Restore Session

    func restoreSession() {
        AuthLogger.event("restoreSession started")
        Task {
            do {
                let session = try await supabase.auth.session
                self.email = session.user.email ?? ""
                AuthLogger.event("Session found", detail: "email=\(session.user.email ?? "nil")")

                // Check if this is a password recovery FIRST (before any profile operations)
                // This prevents overwriting the cloud profile with a blank local profile
                let pendingRecovery = UserDefaults.standard.bool(forKey: "pendingPasswordRecovery")
                AuthLogger.flag("pendingPasswordRecovery", value: pendingRecovery)

                if pendingRecovery {
                    UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
                    AuthLogger.stateChange(from: authState, to: .settingNewPassword, reason: "pendingPasswordRecovery flag detected")
                    authState = .settingNewPassword
                    return // Don't sync profile - updatePassword() will fetch it after password change
                }

                // Fetch existing profile from cloud first (preserves onboardingComplete for returning users)
                // This matches the signIn() approach — fetch remote BEFORE setting .authenticated
                if let remoteProfile = try? await SupabaseDataService.shared.fetchProfile() {
                    try? storageService.saveProfile(remoteProfile)
                    AuthLogger.event("Profile fetched from cloud", detail: "onboardingComplete=\(remoteProfile.onboardingComplete)")
                } else {
                    // Fetch failed or new user — fall back to local profile or create placeholder
                    syncProfileFromSession(session.user)
                    AuthLogger.event("Cloud fetch failed, using local profile")
                }

                // Check block status
                if let profile = syncDataService.loadProfile() {
                    AuthLogger.event("Profile loaded", detail: "onboardingComplete=\(profile.onboardingComplete), isBlocked=\(profile.isBlocked)")
                    if checkIfBlocked(profile) {
                        AuthLogger.stateChange(from: authState, to: .unauthenticated, reason: "user blocked")
                        authState = .unauthenticated
                        return
                    }
                }

                AuthLogger.stateChange(from: authState, to: .authenticated, reason: "session restored")
                authState = .authenticated

                // Full sync in background for other data (messages, journal, etc.)
                Task.detached { [weak self, syncDataService] in
                    await syncDataService.syncFromCloud()
                    await MainActor.run { [weak self, syncDataService] in
                        if let profile = syncDataService.loadProfile() {
                            self?.checkIfBlocked(profile)
                        }
                    }
                }
            } catch {
                AuthLogger.error("restoreSession - no valid session", error: error)
                // No valid session — fall back to local profile check
                if let profile = syncDataService.loadProfile(),
                   !profile.email.isEmpty {
                    AuthLogger.event("Falling back to local profile", detail: "email=\(profile.email)")
                    // Check if blocked even for local profile
                    if checkIfBlocked(profile) {
                        authState = .unauthenticated
                        return
                    }
                    email = profile.email
                    AuthLogger.stateChange(from: authState, to: .authenticated, reason: "local profile fallback")
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
        var profile = syncDataService.loadProfile() ?? Profile()
        if profile.email.isEmpty {
            profile.email = "dev@chloe.test"
        }
        profile.onboardingComplete = true
        profile.updatedAt = Date()
        try? syncDataService.saveProfile(profile)
        self.email = profile.email
        authState = .authenticated
    }
    #endif

    // MARK: - Helpers

    private func syncProfileFromSession(_ user: User) {
        let existingProfile = syncDataService.loadProfile()
        var profile = existingProfile ?? Profile(id: user.id.uuidString)
        profile.email = user.email ?? profile.email
        // Only set updatedAt if profile already existed locally (user-modified)
        // For new profiles, use distant past so cloud profile wins during sync
        if existingProfile == nil {
            profile.updatedAt = .distantPast
        }
        try? syncDataService.saveProfile(profile)
    }

    /// Classify auth errors into safe, non-PII categories for analytics
    private func classifyAuthError(_ error: Error) -> String {
        let message = String(describing: error).lowercased()
        if message.contains("rate") || message.contains("429") || message.contains("limit") {
            return "rateLimited"
        }
        if message.contains("invalid login") || message.contains("invalid_credentials") {
            return "invalidCredentials"
        }
        if message.contains("email not confirmed") {
            return "emailNotConfirmed"
        }
        if message.contains("already registered") || message.contains("already been registered") {
            return "emailAlreadyRegistered"
        }
        if message.contains("password") && message.contains("short") {
            return "passwordTooShort"
        }
        if message.contains("validate email") || message.contains("invalid email") || message.contains("invalid format") {
            return "invalidEmail"
        }
        if message.contains("network") || message.contains("offline") || message.contains("internet") {
            return "networkError"
        }
        return "unknown"
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

// MARK: - Protocol Conformance

extension AuthService: AuthServiceProtocol {}
