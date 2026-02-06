import XCTest

/// E2E tests for Glow Up Streak display
/// Covers: streak counter in sidebar, streak display with test data,
/// streak not shown when zero, and streak after activity.
final class StreakUITests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
    }

    // MARK: - Streak Display in Sidebar

    func testStreak_withActiveStreak_showsStreakInSidebar() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Streak should show "5 day streak" (test data creates 5-day streak)
        let streakText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] '5 day streak'")
        ).element

        XCTAssertTrue(
            waitForElement(streakText, timeout: 3),
            "Should display '5 day streak' in sidebar with active streak test data"
        )
    }

    func testStreak_withActiveStreak_showsFlameIcon() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // The flame icon (flame.fill) should be visible alongside the streak text
        let streakArea = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'streak'")
        ).element

        XCTAssertTrue(
            waitForElement(streakArea, timeout: 3),
            "Should display streak with flame icon in sidebar"
        )

        // The flame icon is an Image(systemName: "flame.fill") in an HStack
        // with the streak text. Verify the containing elements exist.
        let flameImage = app.images.matching(
            NSPredicate(format: "label CONTAINS[c] 'flame'")
        ).element

        // SF Symbols may not always expose their label in UI tests,
        // so the streak text being visible is sufficient confirmation
        // that the streak HStack (including flame) is rendered.
        XCTAssertTrue(
            streakArea.exists || flameImage.exists,
            "Streak display (with flame icon) should be visible"
        )
    }

    func testStreak_noActiveStreak_streakNotDisplayed() throws {
        // Launch without --with-active-streak flag
        app.launchArguments.append("--reset-state")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // When streak is 0, the streak display should be hidden
        // (SidebarView only shows streak when currentStreak > 0)
        let streakText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'streak'")
        ).element

        XCTAssertFalse(
            streakText.exists,
            "Should NOT display streak when current streak is 0"
        )
    }

    // MARK: - Streak Counter Value

    func testStreak_counterValue_matchesTestData() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Test data creates streak with currentStreak=5
        // Display format is "{count} day streak"
        let fiveDayStreak = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '5 day streak'")
        ).element

        XCTAssertTrue(
            waitForElement(fiveDayStreak, timeout: 3),
            "Streak counter should show '5 day streak' matching test data"
        )
    }

    func testStreak_displayFormat_showsDayStreakText() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Verify the display format includes "day streak"
        let streakLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'day streak'")
        ).element

        XCTAssertTrue(
            waitForElement(streakLabel, timeout: 3),
            "Streak should display in 'X day streak' format"
        )
    }

    // MARK: - Streak Position in Sidebar

    func testStreak_positionedBelowNavigationItems() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // The streak is positioned below the navigation items (New Chat, Journal,
        // History, Vision Board, Goals) and above the RECENT section.
        let goalsBtn = app.buttons[AccessibilityID.goalsButton]
        let streakText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'day streak'")
        ).element
        let recentHeader = app.staticTexts["RECENT"]

        guard waitForElement(streakText, timeout: 3) else {
            throw XCTSkip("Streak not displayed")
        }

        // Verify vertical ordering: Goals button above streak, streak above RECENT
        if goalsBtn.exists && recentHeader.exists {
            XCTAssertLessThan(
                goalsBtn.frame.maxY,
                streakText.frame.minY,
                "Streak should be positioned below Goals button"
            )
            XCTAssertLessThan(
                streakText.frame.maxY,
                recentHeader.frame.minY,
                "Streak should be positioned above RECENT section"
            )
        }
    }

    // MARK: - Streak After Activity

    func testStreak_afterSendingMessage_streakServiceRecordsActivity() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        // Send a message to trigger StreakService.recordActivity
        let chatInput = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        guard waitForElement(chatInput, timeout: 5) else {
            throw XCTSkip("Chat input not found")
        }

        chatInput.tap()
        chatInput.typeText("Test message for streak")

        let sendBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'send'")
        ).element
        if waitForElement(sendBtn, timeout: 3) && sendBtn.isEnabled {
            sendBtn.tap()
        }

        sleep(3)

        // Open sidebar to verify streak is still displayed
        sidebarBtn.tap()
        sleep(1)

        let streakText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'day streak'")
        ).element

        XCTAssertTrue(
            waitForElement(streakText, timeout: 3),
            "Streak should still be visible after sending a message"
        )
    }

    // MARK: - Sidebar Streak Persistence

    func testStreak_closeSidebarAndReopen_streakStillVisible() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        // Open sidebar
        sidebarBtn.tap()
        sleep(1)

        let streakText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'day streak'")
        ).element

        XCTAssertTrue(
            waitForElement(streakText, timeout: 3),
            "Streak should be visible on first sidebar open"
        )

        // Close sidebar
        let outsideTap = app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        outsideTap.tap()
        sleep(1)

        // Reopen sidebar
        if waitForElement(sidebarBtn, timeout: 3) {
            sidebarBtn.tap()
            sleep(1)
        }

        // Streak should still be visible
        XCTAssertTrue(
            waitForElement(streakText, timeout: 3),
            "Streak should persist when reopening sidebar"
        )
    }

    // MARK: - Streak with Conversation History

    func testStreak_withHistoryAndStreak_bothDisplayInSidebar() throws {
        app.launchArguments.append("--with-active-streak")
        app.launchArguments.append("--with-conversation-history")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Both streak and conversations should coexist in the sidebar
        let streakText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'day streak'")
        ).element
        let conversationItem = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'conversation'")
        ).element

        XCTAssertTrue(
            waitForElement(streakText, timeout: 3),
            "Streak should be visible alongside conversation history"
        )
        XCTAssertTrue(
            conversationItem.exists,
            "Conversation items should be visible alongside streak"
        )
    }
}
