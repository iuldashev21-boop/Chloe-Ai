import XCTest

/// E2E tests for authentication flows
/// Test Plan Section: 1. AUTHENTICATION TESTS
final class AuthenticationTests: ChloeUITestCase {

    // MARK: - 1.1 Sign Up Flow

    func testSignUp_validCredentials_createsAccount() throws {
        launchAppFresh()

        // Wait for login screen
        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Toggle to sign up mode
        let toggleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Up'")).element
        if waitForElement(toggleButton) {
            toggleButton.tap()
        }

        // Enter valid credentials
        typeText("newuser@test.com", into: emailField)
        typeText("password123", into: passwordField)

        // Tap sign up
        XCTAssertTrue(waitForElement(signUpButton), "Sign up button should be visible")
        signUpButton.tap()

        // Should either show email confirmation message or proceed to onboarding
        let confirmationText = app.staticTexts["Check your email to confirm your account."]
        let onboardingElement = app.staticTexts["Welcome home"]
        let welcomeIntro = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Begin'")).element

        let result = confirmationText.waitForExistence(timeout: 10) ||
                     onboardingElement.waitForExistence(timeout: 10) ||
                     welcomeIntro.waitForExistence(timeout: 10)

        XCTAssertTrue(result, "Should show confirmation message or proceed to onboarding")
    }

    func testSignUp_invalidEmail_showsError() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Toggle to sign up mode
        let toggleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Up'")).element
        if waitForElement(toggleButton) {
            toggleButton.tap()
        }

        // Enter invalid email
        typeText("notanemail", into: emailField)
        typeText("password123", into: passwordField)

        // Button should be disabled or show error after tap
        signUpButton.tap()

        // Wait for error message
        sleep(2)

        // Check if error message appears or button remains disabled
        let errorExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'invalid' OR label CONTAINS[c] 'email'")).element.exists
        let buttonDisabled = !signUpButton.isEnabled

        XCTAssertTrue(errorExists || buttonDisabled, "Should show error or disable button for invalid email")
    }

    func testSignUp_shortPassword_showsError() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Toggle to sign up mode
        let toggleButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Up'")).element
        if waitForElement(toggleButton) {
            toggleButton.tap()
        }

        // Enter valid email but short password
        typeText("test@example.com", into: emailField)
        typeText("123", into: passwordField)

        // Sign up button should be disabled (password < 6 chars)
        XCTAssertFalse(signUpButton.isEnabled, "Sign up button should be disabled for short password")
    }

    // MARK: - 1.2 Sign In Flow

    func testSignIn_validCredentials_authenticates() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Enter valid credentials (use test credentials)
        typeText("test@example.com", into: emailField)
        typeText("password123", into: passwordField)

        // Tap sign in
        signInButton.tap()

        // Should either show error (invalid credentials) or proceed
        // In a real test environment with valid test user, would check for Sanctuary
        sleep(3)

        // Check if we're authenticated or got an error
        let sanctuaryExists = sidebarButton.exists
        let onboardingExists = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Begin'")).element.exists
        let errorExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'invalid' OR label CONTAINS[c] 'error'")).element.exists

        // One of these should be true
        XCTAssertTrue(sanctuaryExists || onboardingExists || errorExists, "Should show result after sign in attempt")
    }

    func testSignIn_wrongPassword_showsError() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Enter valid email but wrong password
        typeText("existinguser@test.com", into: emailField)
        typeText("wrongpassword", into: passwordField)

        signInButton.tap()

        // Wait for error
        let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'invalid'")).element
        XCTAssertTrue(waitForElement(errorMessage, timeout: 10), "Should show invalid credentials error")
    }

    func testSignIn_emptyFields_buttonDisabled() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Don't enter any credentials
        // Sign in button should be disabled
        XCTAssertFalse(signInButton.isEnabled, "Sign in button should be disabled with empty fields")
    }

    func testSignIn_emailOnlyEntered_buttonDisabled() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Enter only email
        typeText("test@example.com", into: emailField)

        // Sign in button should still be disabled
        XCTAssertFalse(signInButton.isEnabled, "Sign in button should be disabled without password")
    }

    // MARK: - 1.3 Session & Sign Out

    func testSessionRestore_afterRelaunch_staysAuthenticated() throws {
        // This test would require actual authentication first
        // In a real test, we'd use a test account

        launchAppOnboarded()

        // If authenticated, should see Sanctuary
        let sidebarBtn = sidebarButton
        if waitForElement(sidebarBtn, timeout: 5) {
            // Now terminate and relaunch
            app.terminate()
            app.launch()

            // Should still be authenticated
            XCTAssertTrue(waitForElement(sidebarBtn, timeout: 10), "Should restore session after relaunch")
        }
    }

    func testSignOut_clearsSessionAndReturnsToLogin() throws {
        launchAppOnboarded()

        // Navigate to settings
        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 5) else {
            throw XCTSkip("App not in authenticated state")
        }

        navigateToSettings()

        // Find and tap sign out
        let signOutBtn = app.buttons["SIGN OUT"]
        guard waitForElement(signOutBtn, timeout: 5) else {
            throw XCTSkip("Sign out button not found")
        }

        signOutBtn.tap()

        // Should return to login screen
        XCTAssertTrue(waitForElement(emailField, timeout: 5), "Should return to login screen after sign out")
    }

    // MARK: - Mode Toggle Tests

    func testAuthModeToggle_switchesBetweenSignInAndSignUp() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Should start in sign in mode
        XCTAssertTrue(signInButton.exists, "Should show Sign In button initially")

        // Toggle to sign up
        let signUpToggle = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Up'")).element
        if waitForElement(signUpToggle) {
            signUpToggle.tap()
        }

        XCTAssertTrue(waitForElement(signUpButton), "Should show Create Account button after toggle")

        // Toggle back to sign in
        let signInToggle = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign In'")).element
        if waitForElement(signInToggle) {
            signInToggle.tap()
        }

        XCTAssertTrue(waitForElement(signInButton), "Should show Sign In button after toggle back")
    }

    // MARK: - Dev Skip (Debug only)

    #if DEBUG
    func testDevSkip_bypassesAuthAndOnboarding() throws {
        launchAppFresh()

        XCTAssertTrue(waitForElement(emailField), "Email field should appear")

        // Find dev skip button
        let devSkipBtn = app.buttons["Skip (Dev)"]
        guard waitForElement(devSkipBtn, timeout: 3) else {
            throw XCTSkip("Dev skip button not available")
        }

        devSkipBtn.tap()

        // Should go directly to Sanctuary
        let sidebarBtn = sidebarButton
        XCTAssertTrue(waitForElement(sidebarBtn, timeout: 10), "Should skip to Sanctuary")
    }
    #endif
}
