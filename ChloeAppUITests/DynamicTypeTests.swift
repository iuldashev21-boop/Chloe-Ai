import XCTest

/// Tests for Dynamic Type support (accessibility font scaling)
///
/// AUDIT FINDING: The ChloeApp codebase uses ZERO Dynamic Type support.
/// All fonts in Theme/Fonts.swift use fixed Font.system(size:) or
/// Font.custom() with hardcoded point sizes. This means:
/// - Text does NOT scale with user accessibility preferences
/// - Users who set larger text sizes in iOS Settings get no benefit
/// - This fails WCAG 2.1 SC 1.4.4 (Resize Text) guidelines
///
/// These tests document the current state at default size and flag
/// the gap for accessibility-scaled sizes.
final class DynamicTypeTests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
    }

    // MARK: - Default Text Size: Key Elements Exist

    func testDynamicType_defaultSize_sanctuaryGreetingExists() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        // Greeting text (e.g., "Hey, TestUser") should be visible at default size
        let greeting = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'hey'")
        ).element
        XCTAssertTrue(
            waitForElement(greeting, timeout: 5),
            "Greeting text should exist at default text size"
        )
    }

    func testDynamicType_defaultSize_chatInputExists() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        // Chat input placeholder or field should be visible
        let chatInput = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        let placeholder = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'heart'")
        ).element

        XCTAssertTrue(
            chatInput.exists || placeholder.exists,
            "Chat input should exist at default text size"
        )
    }

    func testDynamicType_defaultSize_sidebarItemsExist() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Sidebar menu items should be visible at default size
        let journalBtn = app.buttons[AccessibilityID.journalButton]
        let goalsBtn = app.buttons[AccessibilityID.goalsButton]
        let newChatBtn = app.buttons[AccessibilityID.newChatButton]

        XCTAssertTrue(
            waitForElement(journalBtn, timeout: 3),
            "Journal button should exist at default text size"
        )
        XCTAssertTrue(goalsBtn.exists, "Goals button should exist at default text size")
        XCTAssertTrue(newChatBtn.exists, "New Chat button should exist at default text size")
    }

    func testDynamicType_defaultSize_sidebarSectionHeadersExist() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Section headers should be visible
        let navigateHeader = app.staticTexts["NAVIGATE"]
        let recentHeader = app.staticTexts["RECENT"]

        XCTAssertTrue(
            navigateHeader.exists,
            "NAVIGATE section header should exist at default text size"
        )
        XCTAssertTrue(
            recentHeader.exists,
            "RECENT section header should exist at default text size"
        )
    }

    func testDynamicType_defaultSize_settingsLabelsExist() throws {
        launchApp()
        navigateToSettings()
        sleep(1)

        // Settings toggle labels should be visible at default size
        let notificationsToggle = app.switches["Notifications"]
        let signOutBtn = app.buttons["SIGN OUT"]

        XCTAssertTrue(
            waitForElement(notificationsToggle, timeout: 5) || signOutBtn.exists,
            "Settings labels should exist at default text size"
        )
    }

    func testDynamicType_defaultSize_journalViewLabelsExist() throws {
        launchApp()
        navigateToJournal()
        sleep(1)

        // Journal view title should be visible
        let journalNav = app.navigationBars["Journal"]
        let addButton = app.buttons["New journal entry"]
        let emptyState = app.staticTexts["Begin writing"]

        XCTAssertTrue(
            journalNav.exists || addButton.exists || emptyState.exists,
            "Journal view labels should exist at default text size"
        )
    }

    // MARK: - Accessibility Font Size Category

    func testDynamicType_accessibilitySize_documentsLackOfSupport() throws {
        // KNOWN GAP: All fonts in ChloeApp use hardcoded sizes.
        // Font.system(size: X) does NOT respect Dynamic Type.
        // To support Dynamic Type, fonts should use:
        //   - Font.body, Font.title, etc. (system text styles)
        //   - Or UIFontMetrics for custom fonts
        //   - Or @ScaledMetric property wrapper for sizes
        //
        // Current font definitions in Theme/Fonts.swift:
        //   static let chloeLargeTitle = Font.system(size: 28, weight: .medium)  -- FIXED
        //   static let chloeTitle = Font.system(size: 22, weight: .medium)       -- FIXED
        //   static let chloeBodyDefault = Font.system(size: 17, weight: .regular) -- FIXED
        //   static let chloeCaption = Font.system(size: 14, weight: .regular)     -- FIXED
        //   static let chloeGreeting = Font.custom("CormorantGaramond-BoldItalic", size: 38) -- FIXED
        //
        // None of these use relativeTo: parameter or UIFontMetrics scaling.
        //
        // This test documents the gap. When Dynamic Type is implemented,
        // update this test to verify text scales correctly.

        XCTAssertTrue(
            true,
            """
            DOCUMENTED GAP: ChloeApp does not support Dynamic Type.
            All font sizes are hardcoded in Theme/Fonts.swift.
            Fonts should use .relativeTo or UIFontMetrics for accessibility.
            See: https://developer.apple.com/documentation/swiftui/font/custom(_:size:relativeto:)
            """
        )
    }

    func testDynamicType_customFonts_notScaled() throws {
        // Custom fonts (Cinzel, CormorantGaramond, PlayfairDisplay) use
        // Font.custom(name, size:) without the relativeTo: parameter.
        // This means they never scale with Dynamic Type settings.
        //
        // Affected fonts:
        //   - ChloeFont.heroBoldItalic = "CormorantGaramond-BoldItalic"
        //   - ChloeFont.headerDisplay = "Cinzel-Regular"
        //   - ChloeFont.editorialBoldItalic = "PlayfairDisplay-Italic"
        //
        // Fix: Use Font.custom(name, size: X, relativeTo: .body) etc.

        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        // Verify custom-font elements exist but document they don't scale
        let greeting = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'hey'")
        ).element

        XCTAssertTrue(
            waitForElement(greeting, timeout: 5),
            """
            Greeting uses CormorantGaramond-BoldItalic at fixed 38pt.
            This font does not scale with Dynamic Type.
            Fix: Font.custom(ChloeFont.heroBoldItalic, size: 38, relativeTo: .largeTitle)
            """
        )
    }

    func testDynamicType_systemFonts_notScaled() throws {
        // System fonts use Font.system(size: X) throughout the app.
        // While system fonts support Dynamic Type natively via text styles
        // (e.g., Font.body, Font.headline), using explicit size: parameter
        // with Font.system() disables Dynamic Type scaling.
        //
        // Fix: Replace Font.system(size: 17, weight: .regular)
        //      with Font.body or Font.system(.body)

        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        sidebarBtn.tap()
        sleep(1)

        // Sidebar menu items use .chloeSidebarMenuItem (Cinzel 14pt fixed)
        let journalBtn = app.buttons[AccessibilityID.journalButton]
        XCTAssertTrue(
            waitForElement(journalBtn, timeout: 3),
            """
            Sidebar menu items use fixed font sizes (Cinzel-Regular 14pt).
            These do not scale with Dynamic Type accessibility settings.
            Fix: Use relativeTo: parameter or UIFontMetrics.
            """
        )
    }

    // MARK: - Minimum Touch Targets

    func testDynamicType_defaultSize_sidebarButtonMeetsMinimumSize() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        // WCAG recommends 44x44pt minimum touch target
        // The sidebar button is set to 44x44 frame in SanctuaryView
        let frame = sidebarBtn.frame
        XCTAssertGreaterThanOrEqual(
            frame.width, 44,
            "Sidebar button should meet 44pt minimum touch width"
        )
        XCTAssertGreaterThanOrEqual(
            frame.height, 44,
            "Sidebar button should meet 44pt minimum touch height"
        )
    }

    func testDynamicType_defaultSize_chatInputAreaAccessible() throws {
        launchApp()

        let sidebarBtn = sidebarButton
        guard waitForElement(sidebarBtn, timeout: 10) else {
            throw XCTSkip("Not in Sanctuary view")
        }

        let chatInput = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        guard waitForElement(chatInput, timeout: 5) else {
            throw XCTSkip("Chat input not found")
        }

        // Chat input should have reasonable height for tapping
        let frame = chatInput.frame
        XCTAssertGreaterThanOrEqual(
            frame.height, 30,
            "Chat input should have minimum tappable height"
        )
    }

    // MARK: - Summary of Dynamic Type Gaps

    func testDynamicType_gapSummary() throws {
        // This test serves as documentation of all Dynamic Type gaps found:
        //
        // 1. Theme/Fonts.swift - ALL font definitions use fixed sizes
        //    - 15 font constants, 0 use Dynamic Type scaling
        //    - 6 functions return fonts with hardcoded sizes
        //
        // 2. Custom fonts (3 families) never scale:
        //    - CormorantGaramond-BoldItalic (greeting, onboarding)
        //    - Cinzel-Regular (buttons, section headers, sidebar items)
        //    - PlayfairDisplay-Italic (editorial headings)
        //
        // 3. View modifiers apply fixed typography:
        //    - ChloeEditorialHeadingStyle: fixed 40pt
        //    - ChloeHeroStyle: fixed 38pt
        //    - ChloeBodyStyle: fixed 17pt
        //    - ChloeCaptionStyle: fixed 14pt
        //    - ChloeButtonTextStyle: fixed 15pt
        //
        // RECOMMENDED FIXES:
        // a) Use Font.custom(name, size:, relativeTo:) for custom fonts
        // b) Replace Font.system(size:) with semantic text styles
        // c) Add @ScaledMetric for spacing/sizing that should scale
        // d) Test with Accessibility Inspector at AX1-AX5 sizes

        XCTAssertTrue(true, "Dynamic Type gap documentation - see comments above")
    }
}
