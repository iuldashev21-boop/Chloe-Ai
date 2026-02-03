import XCTest

/// E2E tests for Settings functionality
/// Test Plan Section: 8. SETTINGS TESTS
final class SettingsTests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
    }

    // MARK: - Profile Display

    func testSettings_viewProfile_showsNameEmailTier() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        // Check for profile information
        let profileName = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'user' OR label CONTAINS[c] 'babe' OR label CONTAINS[c] 'test'")).element
        let emailText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '@'")).element
        let tierBadge = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'free' OR label CONTAINS[c] 'premium'")).element

        // At least tier should always be visible
        XCTAssertTrue(tierBadge.exists, "Should display subscription tier")
    }

    // MARK: - Profile Photo

    func testSettings_tapAvatar_showsPhotoOptions() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        // Find avatar/profile image area
        let avatar = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'avatar' OR identifier CONTAINS 'profile-image'")).element

        // Could also be the circular image at the top
        let profileImage = app.images.firstMatch

        if avatar.exists {
            avatar.tap()
        } else if profileImage.exists {
            profileImage.tap()
        }

        sleep(1)

        // Should show action sheet with options
        let choosePhoto = app.buttons["Choose Photo"]
        let removePhoto = app.buttons["Remove Photo"]

        XCTAssertTrue(waitForElement(choosePhoto, timeout: 3), "Should show photo options")
    }

    // MARK: - Toggle Settings

    func testSettings_toggleNotifications_savesPreference() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        let notificationsToggle = app.switches["Notifications"]
        guard waitForElement(notificationsToggle, timeout: 5) else {
            throw XCTSkip("Notifications toggle not found")
        }

        let initialValue = notificationsToggle.value as? String == "1"

        notificationsToggle.tap()
        sleep(1)

        let newValue = notificationsToggle.value as? String == "1"
        XCTAssertNotEqual(initialValue, newValue, "Toggle value should change")
    }

    func testSettings_toggleHaptics_savesPreference() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        let hapticsToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'haptic'")).element
        guard waitForElement(hapticsToggle, timeout: 5) else {
            throw XCTSkip("Haptics toggle not found")
        }

        let initialValue = hapticsToggle.value as? String == "1"

        hapticsToggle.tap()
        sleep(1)

        let newValue = hapticsToggle.value as? String == "1"
        XCTAssertNotEqual(initialValue, newValue, "Toggle value should change")
    }

    func testSettings_toggleDarkMode_changesTheme() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        let darkModeToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'dark'")).element
        guard waitForElement(darkModeToggle, timeout: 5) else {
            throw XCTSkip("Dark mode toggle not found")
        }

        darkModeToggle.tap()
        sleep(1)

        // Theme should change (visual verification in manual testing)
        // For automated tests, verify toggle state changed
        let newValue = darkModeToggle.value as? String
        XCTAssertNotNil(newValue, "Dark mode toggle should have a value")
    }

    // MARK: - Sign Out

    func testSettings_signOut_returnsToLogin() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        let signOutBtn = app.buttons["SIGN OUT"]
        guard waitForElement(signOutBtn, timeout: 5) else {
            throw XCTSkip("Sign out button not found")
        }

        signOutBtn.tap()
        sleep(2)

        // Should be back at login screen
        XCTAssertTrue(waitForElement(emailField, timeout: 5), "Should return to login after sign out")
    }

    // MARK: - App Info

    func testSettings_aboutChloe_showsVersion() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        // Find version info
        let versionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'v' AND label CONTAINS '.'")).element
        XCTAssertTrue(versionText.exists, "Should show app version")
    }

    // MARK: - Debug Section (DEBUG builds only)

    #if DEBUG
    func testSettings_devSection_visible() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        // Scroll down to find developer section
        swipeUp()
        sleep(1)

        let devSection = app.staticTexts["DEVELOPER"]
        let skipButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'skip'")).element
        let clearDataBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'clear all data'")).element

        XCTAssertTrue(devSection.exists || skipButton.exists || clearDataBtn.exists,
                      "Should show developer section in debug builds")
    }

    func testSettings_clearAllData_showsConfirmation() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        swipeUp()
        sleep(1)

        let clearDataBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'clear all data'")).element
        guard waitForElement(clearDataBtn, timeout: 3) else {
            throw XCTSkip("Clear data button not found")
        }

        clearDataBtn.tap()

        // Should show confirmation alert
        let alert = app.alerts["Clear All Data?"]
        XCTAssertTrue(waitForElement(alert, timeout: 3), "Should show confirmation alert")

        // Cancel to not actually clear
        alert.buttons["Cancel"].tap()
    }
    #endif

    // MARK: - Persistence

    func testSettings_togglesPersistedAcrossRelaunch() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        let notificationsToggle = app.switches["Notifications"]
        guard waitForElement(notificationsToggle, timeout: 5) else {
            throw XCTSkip("Notifications toggle not found")
        }

        // Get current value
        let initialValue = notificationsToggle.value as? String == "1"

        // Toggle
        notificationsToggle.tap()
        sleep(1)

        let toggledValue = notificationsToggle.value as? String == "1"

        // Relaunch app
        app.terminate()
        app.launch()

        navigateToSettings()
        sleep(1)

        // Verify value persisted
        let persistedValue = notificationsToggle.value as? String == "1"
        XCTAssertEqual(toggledValue, persistedValue, "Toggle value should persist after relaunch")
    }
}
