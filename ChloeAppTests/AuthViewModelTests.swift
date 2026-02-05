import XCTest
@testable import ChloeApp

/// Unit tests for AuthViewModel — covers pure logic, state transitions, and flag cleanup
/// Tests are organized by the 6 auth fixes applied in Phase 3
@MainActor
final class AuthViewModelTests: XCTestCase {

    private var sut: AuthViewModel!

    override func setUp() {
        super.setUp()
        sut = AuthViewModel()
        // Clear any stale flags from previous tests
        UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
        UserDefaults.standard.removeObject(forKey: "awaitingPasswordReset")
        StorageService.shared.clearAll()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "pendingPasswordRecovery")
        UserDefaults.standard.removeObject(forKey: "awaitingPasswordReset")
        StorageService.shared.clearAll()
        sut = nil
        super.tearDown()
    }

    // MARK: - AuthState Enum Tests

    func testAuthState_displayName_unauthenticated() {
        XCTAssertEqual(AuthState.unauthenticated.displayName, "unauthenticated")
    }

    func testAuthState_displayName_authenticating() {
        XCTAssertEqual(AuthState.authenticating.displayName, "authenticating")
    }

    func testAuthState_displayName_awaitingEmailConfirmation() {
        let state = AuthState.awaitingEmailConfirmation(email: "test@test.com")
        XCTAssertEqual(state.displayName, "awaitingEmailConfirmation(test@test.com)")
    }

    func testAuthState_displayName_settingNewPassword() {
        XCTAssertEqual(AuthState.settingNewPassword.displayName, "settingNewPassword")
    }

    func testAuthState_displayName_authenticated() {
        XCTAssertEqual(AuthState.authenticated.displayName, "authenticated")
    }

    func testAuthState_equatable() {
        XCTAssertEqual(AuthState.unauthenticated, AuthState.unauthenticated)
        XCTAssertEqual(AuthState.authenticated, AuthState.authenticated)
        XCTAssertNotEqual(AuthState.unauthenticated, AuthState.authenticated)
        XCTAssertEqual(
            AuthState.awaitingEmailConfirmation(email: "a@b.com"),
            AuthState.awaitingEmailConfirmation(email: "a@b.com")
        )
        XCTAssertNotEqual(
            AuthState.awaitingEmailConfirmation(email: "a@b.com"),
            AuthState.awaitingEmailConfirmation(email: "x@y.com")
        )
    }

    // MARK: - Computed Properties

    func testIsAuthenticated_true() {
        sut.authState = .authenticated
        XCTAssertTrue(sut.isAuthenticated)
    }

    func testIsAuthenticated_false() {
        sut.authState = .unauthenticated
        XCTAssertFalse(sut.isAuthenticated)

        sut.authState = .authenticating
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testIsLoading_true() {
        sut.authState = .authenticating
        XCTAssertTrue(sut.isLoading)
    }

    func testIsLoading_false() {
        sut.authState = .unauthenticated
        XCTAssertFalse(sut.isLoading)

        sut.authState = .authenticated
        XCTAssertFalse(sut.isLoading)
    }

    func testShowEmailConfirmation_true() {
        sut.authState = .awaitingEmailConfirmation(email: "test@test.com")
        XCTAssertTrue(sut.showEmailConfirmation)
    }

    func testShowEmailConfirmation_false() {
        sut.authState = .unauthenticated
        XCTAssertFalse(sut.showEmailConfirmation)

        sut.authState = .authenticated
        XCTAssertFalse(sut.showEmailConfirmation)
    }

    func testShowEmailConfirmation_settingFalse_transitionsToUnauthenticated() {
        sut.authState = .awaitingEmailConfirmation(email: "test@test.com")
        sut.showEmailConfirmation = false
        XCTAssertEqual(sut.authState, .unauthenticated)
    }

    func testPendingConfirmationEmail_returnsEmail() {
        sut.authState = .awaitingEmailConfirmation(email: "test@test.com")
        XCTAssertEqual(sut.pendingConfirmationEmail, "test@test.com")
    }

    func testPendingConfirmationEmail_returnsEmpty_whenNotAwaiting() {
        sut.authState = .unauthenticated
        XCTAssertEqual(sut.pendingConfirmationEmail, "")
    }

    func testShowNewPasswordScreen_true() {
        sut.authState = .settingNewPassword
        XCTAssertTrue(sut.showNewPasswordScreen)
    }

    func testShowNewPasswordScreen_false() {
        sut.authState = .unauthenticated
        XCTAssertFalse(sut.showNewPasswordScreen)
    }

    // MARK: - Fix 3: checkIfBlocked

    func testCheckIfBlocked_blockedProfile_returnsTrue() {
        let profile = Profile(isBlocked: true)
        let result = sut.checkIfBlocked(profile)
        XCTAssertTrue(result)
        XCTAssertEqual(sut.authState, .unauthenticated)
        XCTAssertEqual(sut.errorMessage, "Your account has been suspended. Contact support@chloe.app")
    }

    func testCheckIfBlocked_normalProfile_returnsFalse() {
        sut.authState = .authenticated
        let profile = Profile(isBlocked: false)
        let result = sut.checkIfBlocked(profile)
        XCTAssertFalse(result)
        XCTAssertEqual(sut.authState, .authenticated, "Should not change auth state for non-blocked user")
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Fix 3: cancelEmailConfirmation

    func testCancelEmailConfirmation_transitionsToUnauthenticated() {
        sut.authState = .awaitingEmailConfirmation(email: "test@test.com")
        sut.isSignUpMode = true

        sut.cancelEmailConfirmation()

        XCTAssertEqual(sut.authState, .unauthenticated)
        XCTAssertFalse(sut.isSignUpMode, "Should reset sign up mode")
    }

    // MARK: - Fix 3: handlePasswordRecovery

    func testHandlePasswordRecovery_transitionsToSettingNewPassword() {
        sut.authState = .unauthenticated

        sut.handlePasswordRecovery()

        XCTAssertEqual(sut.authState, .settingNewPassword)
    }

    // MARK: - Fix 4: signOut clears auth flags

    func testSignOut_clearsAuthFlags() {
        // Set up flags that should be cleared
        UserDefaults.standard.set(true, forKey: "pendingPasswordRecovery")
        UserDefaults.standard.set(true, forKey: "awaitingPasswordReset")
        sut.authState = .authenticated
        sut.email = "test@test.com"
        sut.errorMessage = "Some error"

        sut.signOut()

        XCTAssertEqual(sut.authState, .unauthenticated)
        XCTAssertEqual(sut.email, "")
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "pendingPasswordRecovery"),
                       "pendingPasswordRecovery should be cleared on sign out")
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "awaitingPasswordReset"),
                       "awaitingPasswordReset should be cleared on sign out")
    }

    func testSignOut_clearsLocalData() {
        // Save some profile data
        let profile = Profile(email: "test@test.com", displayName: "Test", onboardingComplete: true)
        try? StorageService.shared.saveProfile(profile)
        sut.authState = .authenticated

        sut.signOut()

        // SyncDataService.clearAll() should clear local storage
        XCTAssertNil(StorageService.shared.loadProfile(), "Profile should be cleared after sign out")
    }

    func testSignOut_fromAnyState_goesToUnauthenticated() {
        // From authenticated
        sut.authState = .authenticated
        sut.signOut()
        XCTAssertEqual(sut.authState, .unauthenticated)

        // From settingNewPassword
        sut.authState = .settingNewPassword
        sut.signOut()
        XCTAssertEqual(sut.authState, .unauthenticated)

        // From awaitingEmailConfirmation
        sut.authState = .awaitingEmailConfirmation(email: "test@test.com")
        sut.signOut()
        XCTAssertEqual(sut.authState, .unauthenticated)
    }

    // MARK: - Fix 4: UserDefaults flag isolation

    func testPasswordResetFlag_setAndClear() {
        // Verify the flag lifecycle
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "awaitingPasswordReset"))

        UserDefaults.standard.set(true, forKey: "awaitingPasswordReset")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "awaitingPasswordReset"))

        // signOut should clear it
        sut.signOut()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "awaitingPasswordReset"))
    }

    func testPendingRecoveryFlag_setAndClear() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "pendingPasswordRecovery"))

        UserDefaults.standard.set(true, forKey: "pendingPasswordRecovery")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "pendingPasswordRecovery"))

        sut.signOut()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "pendingPasswordRecovery"))
    }

    // MARK: - State transition sanity checks

    func testInitialState_isUnauthenticated() {
        let vm = AuthViewModel()
        XCTAssertEqual(vm.authState, .unauthenticated)
        XCTAssertEqual(vm.email, "")
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.successMessage)
        XCTAssertFalse(vm.isSignUpMode)
    }

    func testMultipleSignOuts_areIdempotent() {
        sut.authState = .authenticated
        sut.signOut()
        sut.signOut()
        sut.signOut()
        XCTAssertEqual(sut.authState, .unauthenticated)
    }
}
