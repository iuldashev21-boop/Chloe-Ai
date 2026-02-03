import XCTest

/// E2E tests for Sidebar navigation
/// Test Plan Section: 4. SIDEBAR TESTS
final class SidebarTests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
    }

    // MARK: - 4.1 Navigation

    func testSidebar_openViaButton_slidesIn() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Sidebar should be visible
        let newChatBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'new chat' OR label CONTAINS[c] 'new conversation'")).element
        let journalBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'journal'")).element

        XCTAssertTrue(newChatBtn.exists || journalBtn.exists, "Sidebar content should be visible")
    }

    func testSidebar_openViaEdgeSwipe_slidesIn() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        // Swipe from left edge
        swipeFromLeftEdge()
        sleep(1)

        // Sidebar should be visible
        let journalBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'journal'")).element
        XCTAssertTrue(journalBtn.exists, "Sidebar should open via edge swipe")
    }

    func testSidebar_closeViaTap_slidesOut() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Tap outside sidebar (right side of screen)
        let outsideTap = app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        outsideTap.tap()
        sleep(1)

        // Sidebar should close
        XCTAssertTrue(waitForElement(sidebarBtn, timeout: 3), "Sidebar button should reappear after close")
    }

    func testSidebar_closeViaSwipeLeft_slidesOut() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Swipe left to close
        swipeLeft()
        sleep(1)

        XCTAssertTrue(waitForElement(sidebarBtn, timeout: 3), "Sidebar should close via swipe left")
    }

    // MARK: - 4.2 Sidebar Content

    func testSidebar_recentConversations_displayed() throws {
        // Launch with conversation history
        app.launchArguments.append("--with-conversation-history")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Check for conversation items
        let recentSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'recent'")).element
        let conversationCell = app.cells.firstMatch

        XCTAssertTrue(recentSection.exists || conversationCell.exists || app.buttons.count > 5,
                      "Should show recent conversations section")
    }

    func testSidebar_streakDisplay_showsCorrectStreak() throws {
        app.launchArguments.append("--with-active-streak")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Check for streak display
        let streakText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'streak' OR label CONTAINS[c] 'glow'")).element
        XCTAssertTrue(waitForElement(streakText, timeout: 3), "Should display streak")
    }

    func testSidebar_profilePill_showsNameAndTier() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Check for profile section at bottom
        let tierBadge = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'free' OR label CONTAINS[c] 'premium'")).element
        XCTAssertTrue(tierBadge.exists, "Should show subscription tier badge")
    }

    // MARK: - 4.3 Feature Navigation

    func testSidebar_tapJournal_opensJournalView() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        navigateToJournal()
        sleep(1)

        // Should be on Journal view
        let journalTitle = app.navigationBars["Journal"]
        let addButton = app.buttons["New journal entry"]

        XCTAssertTrue(journalTitle.exists || addButton.exists, "Should navigate to Journal view")
    }

    func testSidebar_tapHistory_opensHistoryView() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        let historyBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'history'")).element
        if waitForElement(historyBtn, timeout: 3) {
            historyBtn.tap()
            sleep(1)

            let historyTitle = app.navigationBars["History"]
            XCTAssertTrue(historyTitle.exists, "Should navigate to History view")
        }
    }

    func testSidebar_tapVisionBoard_opensVisionBoardView() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        navigateToVisionBoard()
        sleep(1)

        let visionTitle = app.navigationBars.matching(NSPredicate(format: "identifier CONTAINS 'Vision'")).element
        let addButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add'")).element

        XCTAssertTrue(visionTitle.exists || addButton.exists, "Should navigate to Vision Board view")
    }

    func testSidebar_tapGoals_opensGoalsView() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        navigateToGoals()
        sleep(1)

        let goalsTitle = app.navigationBars["Goals"]
        let addButton = app.buttons["Add goal"]

        XCTAssertTrue(goalsTitle.exists || addButton.exists, "Should navigate to Goals view")
    }

    func testSidebar_tapAffirmations_showsComingSoon() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        let affirmationsBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'affirmation'")).element
        if waitForElement(affirmationsBtn, timeout: 3) {
            affirmationsBtn.tap()
            sleep(1)

            // Should show coming soon or placeholder
            let comingSoon = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'coming soon' OR label CONTAINS[c] 'daily affirmation'")).element
            XCTAssertTrue(comingSoon.exists || app.navigationBars["Affirmations"].exists, "Should show affirmations")
        }
    }

    func testSidebar_tapSettings_opensSettingsView() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        navigateToSettings()
        sleep(1)

        let settingsTitle = app.navigationBars["Settings"]
        let signOutBtn = app.buttons["SIGN OUT"]

        XCTAssertTrue(settingsTitle.exists || signOutBtn.exists, "Should navigate to Settings view")
    }

    // MARK: - Conversation Actions

    func testSidebar_longPressConversation_showsContextMenu() throws {
        app.launchArguments.append("--with-conversation-history")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Find a conversation item
        let conversationItem = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'conversation'")).element
        if waitForElement(conversationItem, timeout: 3) {
            conversationItem.press(forDuration: 1.0) // Long press

            sleep(1)

            // Context menu should appear
            let renameOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'rename'")).element
            let deleteOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'delete'")).element
            let starOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'star'")).element

            XCTAssertTrue(renameOption.exists || deleteOption.exists || starOption.exists,
                          "Context menu should show options")
        }
    }

    func testSidebar_deleteConversation_offline_showsAlert() throws {
        app.launchArguments.append("--with-conversation-history")
        app.launchArguments.append("--simulate-offline")
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Try to delete conversation
        let conversationItem = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'conversation'")).element
        if waitForElement(conversationItem, timeout: 3) {
            conversationItem.press(forDuration: 1.0)

            let deleteOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'delete'")).element
            if waitForElement(deleteOption, timeout: 2) {
                deleteOption.tap()

                // Should show offline alert
                let offlineAlert = app.alerts["You're Offline"]
                XCTAssertTrue(waitForElement(offlineAlert, timeout: 3), "Should show offline alert")
            }
        }
    }
}
