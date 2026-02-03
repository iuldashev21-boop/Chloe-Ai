import XCTest

/// Base class for ChloeApp UI tests with common helpers
class ChloeUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment["UITEST_MODE"] = "1"
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Helpers

    func launchApp() {
        app.launch()
    }

    func launchAppFresh() {
        app.launchArguments.append("--reset-state")
        app.launch()
    }

    func launchAppAuthenticated() {
        app.launchArguments.append("--skip-auth")
        app.launch()
    }

    func launchAppOnboarded() {
        app.launchArguments.append("--skip-onboarding")
        app.launch()
    }

    // MARK: - Wait Helpers

    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element should disappear")
    }

    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    // MARK: - Common Elements

    var emailField: XCUIElement {
        // Use accessibility identifier set in EmailLoginView
        let byIdentifier = app.textFields["email-field"]
        if byIdentifier.exists { return byIdentifier }
        // Fallback to label
        return app.textFields["Email address"]
    }

    var passwordField: XCUIElement {
        // Use accessibility identifier set in EmailLoginView
        let byIdentifier = app.secureTextFields["password-field"]
        if byIdentifier.exists { return byIdentifier }
        // Fallback to label
        return app.secureTextFields["Password"]
    }

    var signInButton: XCUIElement {
        app.buttons["SIGN IN"]
    }

    var signUpButton: XCUIElement {
        app.buttons["CREATE ACCOUNT"]
    }

    var sidebarButton: XCUIElement {
        // Use accessibility identifier set in SanctuaryView
        let byIdentifier = app.buttons["sidebar-button"]
        if byIdentifier.exists { return byIdentifier }
        // Fallback to label
        return app.buttons["Open sidebar"]
    }

    var newChatButton: XCUIElement {
        // Use accessibility identifier set in SidebarView
        let byIdentifier = app.buttons["new-chat-button"]
        if byIdentifier.exists { return byIdentifier }
        // Fallback to label
        return app.buttons["New Chat"]
    }

    // MARK: - Text Input Helpers

    func typeText(_ text: String, into element: XCUIElement) {
        element.tap()
        element.typeText(text)
    }

    func clearAndType(_ text: String, into element: XCUIElement) {
        element.tap()

        // Select all and delete
        let selectAllMenuItem = app.menuItems["Select All"]
        if selectAllMenuItem.waitForExistence(timeout: 1) {
            selectAllMenuItem.tap()
            app.keys["delete"].tap()
        } else {
            // Fallback: clear character by character
            if let currentValue = element.value as? String {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
                element.typeText(deleteString)
            }
        }

        element.typeText(text)
    }

    // MARK: - Gesture Helpers

    func swipeFromLeftEdge() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    func swipeRight() {
        app.swipeRight()
    }

    func swipeLeft() {
        app.swipeLeft()
    }

    func swipeUp() {
        app.swipeUp()
    }

    func swipeDown() {
        app.swipeDown()
    }

    // MARK: - Navigation Helpers

    func navigateToSidebar() {
        if waitForElement(sidebarButton) {
            sidebarButton.tap()
        }
    }

    func navigateToJournal() {
        navigateToSidebar()
        // Use identifier from SidebarView
        let journalButton = app.buttons["journal-button"]
        if waitForElement(journalButton) {
            journalButton.tap()
        }
    }

    func navigateToGoals() {
        navigateToSidebar()
        // Use identifier from SidebarView
        let goalsButton = app.buttons["goals-button"]
        if waitForElement(goalsButton) {
            goalsButton.tap()
        }
    }

    func navigateToVisionBoard() {
        navigateToSidebar()
        // Use identifier from SidebarView
        let visionButton = app.buttons["vision-board-button"]
        if waitForElement(visionButton) {
            visionButton.tap()
        }
    }

    func navigateToSettings() {
        navigateToSidebar()
        // Settings is accessed via profile pill with identifier "settings-button"
        let settingsButton = app.buttons["settings-button"]
        if waitForElement(settingsButton) {
            settingsButton.tap()
        }
    }

    func goBack() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists && backButton.isHittable {
            backButton.tap()
        }
    }

    // MARK: - Assertion Helpers

    func assertExists(_ element: XCUIElement, _ message: String = "") {
        XCTAssertTrue(element.exists, message.isEmpty ? "Element should exist" : message)
    }

    func assertNotExists(_ element: XCUIElement, _ message: String = "") {
        XCTAssertFalse(element.exists, message.isEmpty ? "Element should not exist" : message)
    }

    func assertVisible(_ element: XCUIElement, _ message: String = "") {
        XCTAssertTrue(element.exists && element.isHittable, message.isEmpty ? "Element should be visible" : message)
    }

    func assertText(_ element: XCUIElement, contains text: String) {
        if let label = element.label as String?, label.contains(text) {
            return
        }
        if let value = element.value as? String, value.contains(text) {
            return
        }
        XCTFail("Element should contain text: \(text)")
    }

    // MARK: - Keyboard Helpers

    func dismissKeyboard() {
        if app.keyboards.element(boundBy: 0).exists {
            app.tap() // Tap outside to dismiss
        }
    }

    func tapReturn() {
        app.keyboards.buttons["Return"].tap()
    }

    // MARK: - Alert Helpers

    func handleAlert(button: String) {
        let alert = app.alerts.element(boundBy: 0)
        if waitForElement(alert, timeout: 2) {
            alert.buttons[button].tap()
        }
    }

    func handleSystemAlert(allow: Bool) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons[allow ? "Allow" : "Don't Allow"]
        if allowButton.waitForExistence(timeout: 2) {
            allowButton.tap()
        }
    }

    // MARK: - Sheet Helpers

    func dismissSheet() {
        // Swipe down to dismiss
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    // MARK: - Debugging

    func printElementTree() {
        print(app.debugDescription)
    }
}

// MARK: - Accessibility Identifiers

enum AccessibilityID {
    // Auth
    static let emailField = "email-field"
    static let passwordField = "password-field"
    static let signInButton = "sign-in-button"
    static let signUpButton = "sign-up-button"
    static let authToggle = "auth-mode-toggle"
    static let errorMessage = "error-message"
    static let devSkipButton = "dev-skip-button"

    // Onboarding
    static let beginJourneyButton = "begin-journey-button"
    static let nameField = "name-field"
    static let continueButton = "continue-button"
    static let skipButton = "skip-button"
    static let backButton = "back-button"
    static let quizOption = "quiz-option"
    static let meetChloeButton = "meet-chloe-button"

    // Sanctuary
    static let sidebarButton = "sidebar-button"
    static let newChatButton = "new-chat-button"
    static let chatInput = "chat-input"
    static let sendButton = "send-button"
    static let typingIndicator = "typing-indicator"
    static let rechargingCard = "recharging-card"
    static let errorBanner = "error-banner"
    static let retryButton = "retry-button"

    // Sidebar
    static let newConversationButton = "new-conversation-button"
    static let conversationItem = "conversation-item"
    static let journalButton = "journal-button"
    static let historyButton = "history-button"
    static let visionBoardButton = "vision-board-button"
    static let goalsButton = "goals-button"
    static let affirmationsButton = "affirmations-button"
    static let settingsButton = "settings-button"

    // Journal
    static let addJournalButton = "add-journal-button"
    static let journalEntryCard = "journal-entry-card"
    static let journalTitleField = "journal-title-field"
    static let journalContentField = "journal-content-field"
    static let saveJournalButton = "save-journal-button"

    // Goals
    static let addGoalButton = "add-goal-button"
    static let goalCard = "goal-card"
    static let goalTitleField = "goal-title-field"
    static let goalCheckbox = "goal-checkbox"
    static let addGoalSaveButton = "add-goal-save-button"

    // Vision Board
    static let addVisionButton = "add-vision-button"
    static let visionCard = "vision-card"
    static let visionTitleField = "vision-title-field"
    static let saveVisionButton = "save-vision-button"

    // Settings
    static let profileAvatar = "profile-avatar"
    static let notificationsToggle = "notifications-toggle"
    static let hapticToggle = "haptic-toggle"
    static let darkModeToggle = "dark-mode-toggle"
    static let signOutButton = "sign-out-button"
}
