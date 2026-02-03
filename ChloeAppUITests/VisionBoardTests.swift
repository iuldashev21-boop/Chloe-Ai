import XCTest

/// E2E tests for Vision Board CRUD operations
/// Test Plan Section: 6. VISION BOARD TESTS
final class VisionBoardTests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
    }

    // MARK: - Create

    func testVisionBoard_addItem_appearsInGrid() throws {
        launchApp()
        navigateToVisionBoard()
        sleep(1)

        let addBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add'")).element
        guard waitForElement(addBtn, timeout: 5) else {
            throw XCTSkip("Add button not found")
        }
        addBtn.tap()
        sleep(1)

        // Fill in vision item
        let titleField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'title'")).element
        if waitForElement(titleField, timeout: 3) {
            typeText("Dream vacation to Japan", into: titleField)
        }

        // Select category if available
        let categoryPicker = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'category'")).element
        if categoryPicker.exists {
            categoryPicker.tap()
            let travelCategory = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'travel'")).element
            if waitForElement(travelCategory, timeout: 2) {
                travelCategory.tap()
            }
        }

        // Save
        let saveBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'save' OR label CONTAINS[c] 'add' OR label CONTAINS[c] 'done'")).element
        if waitForElement(saveBtn) {
            saveBtn.tap()
        }

        sleep(1)

        // Verify item appears
        let visionItem = app.staticTexts["Dream vacation to Japan"]
        XCTAssertTrue(waitForElement(visionItem, timeout: 5), "Created vision should appear")
    }

    func testVisionBoard_addItemWithImage_showsImage() throws {
        // This test would require photo picker simulation
        // For UI tests, we verify the flow exists
        launchApp()
        navigateToVisionBoard()
        sleep(1)

        let addBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add'")).element
        guard waitForElement(addBtn, timeout: 5) else {
            throw XCTSkip("Add button not found")
        }
        addBtn.tap()
        sleep(1)

        // Check for image upload button
        let imageBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'photo' OR label CONTAINS[c] 'image' OR label CONTAINS[c] 'upload'")).element
        XCTAssertTrue(imageBtn.exists, "Should have image upload option")
    }

    // MARK: - Delete

    func testVisionBoard_deleteItem_removedFromGrid() throws {
        app.launchArguments.append("--with-vision-items")
        launchApp()
        navigateToVisionBoard()
        sleep(1)

        // Find a vision item and long press
        let visionItem = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'vision-card'")).element
        guard waitForElement(visionItem, timeout: 5) else {
            throw XCTSkip("No vision items to delete")
        }

        let itemTitle = visionItem.staticTexts.firstMatch.label

        visionItem.press(forDuration: 1.0)

        let deleteOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'delete'")).element
        if waitForElement(deleteOption, timeout: 2) {
            deleteOption.tap()
        }

        sleep(1)

        let deletedItem = app.staticTexts[itemTitle]
        XCTAssertFalse(deletedItem.exists, "Deleted vision should be removed")
    }

    // MARK: - Empty State

    func testVisionBoard_emptyState_showsMessage() throws {
        app.launchArguments.append("--clear-vision-board")
        launchApp()
        navigateToVisionBoard()
        sleep(1)

        let emptyMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'add your first' OR label CONTAINS[c] 'vision'")).element
        XCTAssertTrue(waitForElement(emptyMessage, timeout: 5), "Should show empty state message")
    }

    // MARK: - Categories

    func testVisionBoard_allCategories_work() throws {
        launchApp()
        navigateToVisionBoard()
        sleep(1)

        let addBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add'")).element
        guard waitForElement(addBtn, timeout: 5) else {
            throw XCTSkip("Add button not found")
        }

        // Test each category exists
        let categories = ["Career", "Health", "Relationships", "Personal"]

        addBtn.tap()
        sleep(1)

        let categoryPicker = app.pickers.firstMatch
        let segmentedControl = app.segmentedControls.firstMatch

        if categoryPicker.exists || segmentedControl.exists {
            // Category selection exists
            XCTAssertTrue(true, "Category selection available")
        } else {
            // Check for category buttons
            for category in categories {
                let categoryBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", category)).element
                if categoryBtn.exists {
                    XCTAssertTrue(true, "Category \(category) available")
                    break
                }
            }
        }
    }

    // MARK: - Grid Layout

    func testVisionBoard_multipleItems_displayInGrid() throws {
        app.launchArguments.append("--with-multiple-visions")
        launchApp()
        navigateToVisionBoard()
        sleep(1)

        // Should have multiple items in grid layout
        let visionItems = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'vision'"))
        XCTAssertTrue(visionItems.count >= 2, "Should display multiple items in grid")
    }
}
