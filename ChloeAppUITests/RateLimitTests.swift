import XCTest

/// E2E tests for Rate Limiting (Free Tier)
/// Test Plan Section: 3.3 RATE LIMITING
final class RateLimitTests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
        app.launchArguments.append("--reset-daily-usage")
    }

    // MARK: - Message Count Tracking

    func testRateLimit_messagesOneToFour_sendNormally() throws {
        launchApp()
        activateChat()

        // Send 4 messages
        for i in 1...4 {
            sendMessage("Test message \(i)")
            sleep(5) // Wait for response
        }

        // Should all send normally - no rate limit card
        let rechargingCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'recharging'")).element
        XCTAssertFalse(rechargingCard.exists, "Should not show rate limit after 4 messages")
    }

    func testRateLimit_messageFive_showsGoodbyeAndReachesLimit() throws {
        // Start with 4 messages already sent
        app.launchArguments.append("--daily-usage-count-4")
        launchApp()
        activateChat()

        // Send 5th message
        sendMessage("This is my fifth message")

        sleep(8) // Wait for response + goodbye

        // Should receive response plus goodbye message
        let goodbyeIndicators = [
            "recharge",
            "tomorrow",
            "signing off",
            "wrap for today"
        ]

        var foundGoodbye = false
        for indicator in goodbyeIndicators {
            let text = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", indicator)).element
            if text.exists {
                foundGoodbye = true
                break
            }
        }

        XCTAssertTrue(foundGoodbye, "Should show goodbye message after 5th message")

        // After goodbye, rate limit should be reached
        sleep(2)
        let rechargingCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'recharging'")).element
        XCTAssertTrue(rechargingCard.exists, "Should show recharging card after goodbye")
    }

    func testRateLimit_messageSix_inputBlocked() throws {
        // Start with limit already reached
        app.launchArguments.append("--daily-usage-limit-reached")
        launchApp()
        activateChat()

        // Rate limit card should be shown
        let rechargingCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'recharging'")).element
        XCTAssertTrue(waitForElement(rechargingCard, timeout: 5), "Should show recharging card")

        // Input should be blocked
        let chatInput = app.textViews.firstMatch
        let textField = app.textFields.firstMatch
        let inputAvailable = (chatInput.exists && chatInput.isEnabled) ||
                            (textField.exists && textField.isEnabled)

        XCTAssertFalse(inputAvailable, "Chat input should be blocked at rate limit")
    }

    func testRateLimit_rechargingCard_showsUnlockButton() throws {
        app.launchArguments.append("--daily-usage-limit-reached")
        launchApp()
        activateChat()

        // Rate limit card should show unlock/upgrade button
        let unlockButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'unlock' OR label CONTAINS[c] 'premium' OR label CONTAINS[c] 'unlimited'")).element
        XCTAssertTrue(waitForElement(unlockButton, timeout: 5), "Should show unlock premium button")
    }

    // MARK: - Daily Reset

    func testRateLimit_dailyReset_allowsMessagingAgain() throws {
        // Simulate daily reset (next day)
        app.launchArguments.append("--simulate-next-day")
        launchApp()
        activateChat()

        // Should be able to send messages again
        let chatInput = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(chatInput.exists && chatInput.isEnabled, "Should allow messaging after daily reset")
    }

    // MARK: - Premium User

    func testRateLimit_premiumUser_noLimit() throws {
        app.launchArguments.append("--premium-user")
        launchApp()
        activateChat()

        // Premium users should never see rate limit
        for i in 1...6 {
            sendMessage("Premium message \(i)")
            sleep(3)
        }

        let rechargingCard = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'recharging'")).element
        XCTAssertFalse(rechargingCard.exists, "Premium users should not see rate limit")
    }

    // MARK: - Race Condition (Known Issue Section 13)

    func testRateLimit_rapidTapOnFifthMessage_sendsOnlyOne() throws {
        app.launchArguments.append("--daily-usage-count-4")
        launchApp()
        activateChat()

        let chatInput = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        guard waitForElement(chatInput, timeout: 5) else {
            throw XCTSkip("Chat input not found")
        }

        chatInput.tap()
        chatInput.typeText("Fifth message test")

        // Rapidly tap send twice
        let sendBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'send'")).element
        if waitForElement(sendBtn, timeout: 2) && sendBtn.isEnabled {
            sendBtn.tap()
            sendBtn.tap() // Second tap should be debounced
        }

        sleep(5)

        // Count user messages - should only have one "Fifth message test"
        let userMessages = app.staticTexts.matching(NSPredicate(format: "label == 'Fifth message test'"))
        XCTAssertEqual(userMessages.count, 1, "Should only send one message despite rapid tapping")
    }

    // MARK: - Helpers

    private func activateChat() {
        _ = waitForElement(sidebarButton, timeout: 10)

        let chatArea = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        chatArea.tap()
        sleep(1)
    }

    private func sendMessage(_ text: String) {
        let chatInput = app.textFields["chat-input"]
        let fallback = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        let input = chatInput.exists ? chatInput : fallback

        if waitForElement(input, timeout: 5) {
            input.tap()
            sleep(1) // Wait for keyboard focus
            input.typeText(text)

            let sendBtn = app.buttons["send-button"]
            let fallbackSend = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'send'")).element
            let btn = sendBtn.exists ? sendBtn : fallbackSend
            if waitForElement(btn, timeout: 2) && btn.isEnabled {
                btn.tap()
            }
        }
    }
}
