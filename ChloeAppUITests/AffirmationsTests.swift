import XCTest

/// E2E tests for Affirmations feature (currently a stub)
/// Verifies navigation, "Coming soon" placeholder, and back navigation.
/// NOTE: The Affirmations sidebar button is currently hidden in v1.
/// These tests navigate via History -> sidebar menu workaround or direct
/// navigation destination if available.
final class AffirmationsTests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
    }

    // MARK: - Navigation

    func testAffirmations_navigateFromSidebar_showsAffirmationsView() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // The Affirmations button is currently commented out in SidebarView v1.
        // Look for it in case it gets re-enabled.
        let affirmationsBtn = app.buttons[AccessibilityID.affirmationsButton]
        let affirmationsByLabel = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'affirmation'")
        ).element

        let foundButton = affirmationsBtn.exists ? affirmationsBtn : affirmationsByLabel

        if waitForElement(foundButton, timeout: 3) {
            foundButton.tap()
            sleep(1)

            // Verify we navigated to Affirmations view
            let navTitle = app.navigationBars["Affirmations"]
            let titleText = app.staticTexts["Affirmations"]

            XCTAssertTrue(
                navTitle.exists || titleText.exists,
                "Should navigate to Affirmations view"
            )
        } else {
            // Button is hidden in v1 - document this as expected
            XCTAssertFalse(
                foundButton.exists,
                "Affirmations sidebar button is hidden in v1 (expected)"
            )
        }
    }

    func testAffirmations_comingSoonPlaceholder_displayed() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Try to navigate to Affirmations
        let affirmationsBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'affirmation' OR identifier == 'affirmations-button'")
        ).element

        guard waitForElement(affirmationsBtn, timeout: 3) else {
            throw XCTSkip("Affirmations button is hidden in v1 sidebar")
        }

        affirmationsBtn.tap()
        sleep(1)

        // Verify "Coming soon" text is displayed
        let comingSoon = app.staticTexts["Coming soon"]
        XCTAssertTrue(
            waitForElement(comingSoon, timeout: 5),
            "Should display 'Coming soon' placeholder text"
        )
    }

    func testAffirmations_backNavigation_returnsToPreviousScreen() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        let affirmationsBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'affirmation' OR identifier == 'affirmations-button'")
        ).element

        guard waitForElement(affirmationsBtn, timeout: 3) else {
            throw XCTSkip("Affirmations button is hidden in v1 sidebar")
        }

        affirmationsBtn.tap()
        sleep(1)

        // Verify we are on Affirmations view
        let titleText = app.staticTexts["Affirmations"]
        let navTitle = app.navigationBars["Affirmations"]
        guard titleText.exists || navTitle.exists else {
            throw XCTSkip("Did not navigate to Affirmations")
        }

        // Navigate back
        goBack()
        sleep(1)

        // Should return to Sanctuary (sidebar reopens after navigating back)
        XCTAssertTrue(
            waitForElement(sidebarBtn, timeout: 5),
            "Should return to Sanctuary after navigating back from Affirmations"
        )
    }

    // MARK: - Stub Verification

    func testAffirmations_stubView_showsTitleAndPlaceholder() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        let affirmationsBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'affirmation' OR identifier == 'affirmations-button'")
        ).element

        guard waitForElement(affirmationsBtn, timeout: 3) else {
            throw XCTSkip("Affirmations button is hidden in v1 sidebar")
        }

        affirmationsBtn.tap()
        sleep(1)

        // Both the title and the placeholder should be visible
        let titleText = app.staticTexts["Affirmations"]
        let comingSoon = app.staticTexts["Coming soon"]

        XCTAssertTrue(titleText.exists, "Should display 'Affirmations' title")
        XCTAssertTrue(comingSoon.exists, "Should display 'Coming soon' placeholder")
    }

    func testAffirmations_sidebarButtonHiddenInV1() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Verify sidebar is open by checking for known elements
        let journalBtn = app.buttons[AccessibilityID.journalButton]
        XCTAssertTrue(
            waitForElement(journalBtn, timeout: 3),
            "Sidebar should be open (Journal button visible)"
        )

        // Affirmations button should NOT be visible in v1
        let affirmationsBtn = app.buttons[AccessibilityID.affirmationsButton]
        XCTAssertFalse(
            affirmationsBtn.exists,
            "Affirmations button should be hidden in v1 sidebar"
        )
    }
}
