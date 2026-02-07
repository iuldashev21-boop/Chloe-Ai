import Foundation
import SwiftUI
import Combine

// MARK: - Auth State

/// Single source of truth for authentication state.
/// Replaces fragmented boolean flags with a clear state machine.
enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case awaitingEmailConfirmation(email: String)
    case settingNewPassword
    case authenticated

    var displayName: String {
        switch self {
        case .unauthenticated: return "unauthenticated"
        case .authenticating: return "authenticating"
        case .awaitingEmailConfirmation(let email): return "awaitingEmailConfirmation(\(email))"
        case .settingNewPassword: return "settingNewPassword"
        case .authenticated: return "authenticated"
        }
    }
}

// MARK: - Auth Logger

/// Structured logging for authentication flows (DEBUG only -- logs may contain PII).
/// All logs use [Auth] prefix for easy filtering: `log stream --predicate 'eventMessage contains "[Auth]"'`
enum AuthLogger {
    static func stateChange(from oldState: AuthState, to newState: AuthState, reason: String) {
        #if DEBUG
        print("[Auth] State: \(oldState.displayName) -> \(newState.displayName) | \(reason)")
        #endif
    }

    static func event(_ event: String, detail: String? = nil) {
        #if DEBUG
        if let detail = detail {
            print("[Auth] \(event) | \(detail)")
        } else {
            print("[Auth] \(event)")
        }
        #endif
    }

    static func error(_ context: String, error: Error) {
        #if DEBUG
        print("[Auth] ERROR: \(context) | \(error.localizedDescription)")
        #endif
    }

    static func flag(_ name: String, value: Bool) {
        #if DEBUG
        print("[Auth] Flag \(name) = \(value)")
        #endif
    }
}

// MARK: - AuthViewModel (Thin UI Layer)

/// Thin UI-layer ViewModel for authentication screens.
///
/// Owns UI-only state (form fields, sign-up mode toggle) and delegates
/// all actual auth operations to `AuthService`. Observes AuthService's
/// published properties and re-publishes them so Views get updates.
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - UI-Only State

    @Published var isSignUpMode = false
    @Published var successMessage: String?

    // MARK: - Forwarded from AuthService

    /// Auth state, forwarded from AuthService so Views observe changes
    @Published var authState: AuthState = .unauthenticated

    /// Email, forwarded from AuthService
    @Published var email = ""

    /// Error message, forwarded from AuthService (also settable from Views)
    @Published var errorMessage: String?

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
                authService.cancelEmailConfirmation()
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

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /// Convenience init using the production AuthService singleton.
    /// Avoids referencing @MainActor-isolated `AuthService.shared` in a default parameter
    /// expression (which is evaluated in the caller's nonisolated context in Swift 6).
    convenience init() {
        self.init(authService: AuthService.shared)
    }

    init(authService: AuthServiceProtocol) {
        self.authService = authService

        // Observe AuthService's published properties and forward to our own @Published
        // so SwiftUI Views that observe this ViewModel get notified of changes.
        // No .receive(on:) needed -- both AuthService and AuthViewModel are @MainActor,
        // so @Published changes already fire on the main actor synchronously.
        if let service = authService as? AuthService {
            service.$authState
                .sink { [weak self] newState in
                    self?.authState = newState
                }
                .store(in: &cancellables)

            service.$email
                .sink { [weak self] newEmail in
                    self?.email = newEmail
                }
                .store(in: &cancellables)

            service.$errorMessage
                .sink { [weak self] newError in
                    self?.errorMessage = newError
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Auth Actions (delegate to AuthService)

    func signIn(email: String, password: String) async {
        successMessage = nil
        await authService.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async {
        successMessage = nil
        await authService.signUp(email: email, password: password)
    }

    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async {
        successMessage = nil
        await authService.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName)
    }

    func resendConfirmationEmail() async {
        await authService.resendConfirmationEmail()
    }

    func cancelEmailConfirmation() {
        authService.cancelEmailConfirmation()
        isSignUpMode = false
    }

    func sendPasswordReset(email: String) async throws {
        try await authService.sendPasswordReset(email: email)
    }

    func updatePassword(_ newPassword: String) async throws {
        try await authService.updatePassword(newPassword)
    }

    func handlePasswordRecovery() {
        authService.handlePasswordRecovery()
    }

    func signOut() {
        authService.signOut()
        successMessage = nil
    }

    func restoreSession() {
        authService.restoreSession()
    }

    @discardableResult
    func checkIfBlocked(_ profile: Profile) -> Bool {
        return authService.checkIfBlocked(profile)
    }

    // MARK: - Dev Skip (DEBUG only)

    #if DEBUG
    func devSignIn() async {
        if let service = authService as? AuthService {
            await service.devSignIn()
        }
    }
    #endif
}
