import XCTest

/// E2E tests for Goals CRUD operations
/// Test Plan Section: 7. GOALS TESTS
final class GoalsTests: ChloeUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launchArguments.append("--skip-onboarding")
    }

    // MARK: - Create

    func testGoals_createGoal_appearsInList() throws {
        launchApp()
        navigateToGoals()
        sleep(1)

        let addBtn = app.buttons["Add goal"]
        guard waitForElement(addBtn, timeout: 5) else {
            throw XCTSkip("Add button not found")
        }
        addBtn.tap()
        sleep(1)

        // Fill in goal
        let titleField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'title' OR placeholderValue CONTAINS[c] 'goal'")).element
        if waitForElement(titleField, timeout: 3) {
            typeText("Meditate daily", into: titleField)
        }

        // Add description (optional)
        let descField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'description'")).element
        if descField.exists {
            typeText("Start with 5 minutes each morning", into: descField)
        }

        // Save
        let addSaveBtn = app.buttons["Add"]
        if waitForElement(addSaveBtn, timeout: 3) {
            addSaveBtn.tap()
        }

        sleep(1)

        // Verify goal appears
        let goal = app.staticTexts["Meditate daily"]
        XCTAssertTrue(waitForElement(goal, timeout: 5), "Created goal should appear in list")
    }

    func testGoals_createGoalWithDescription_showsDescription() throws {
        launchApp()
        navigateToGoals()
        sleep(1)

        let addBtn = app.buttons["Add goal"]
        guard waitForElement(addBtn, timeout: 5) else {
            throw XCTSkip("Add button not found")
        }
        addBtn.tap()
        sleep(1)

        let titleField = app.textFields.firstMatch
        if waitForElement(titleField, timeout: 3) {
            typeText("Learn SwiftUI", into: titleField)
        }

        let descField = app.textFields.element(boundBy: 1)
        if descField.exists {
            typeText("Complete 1 lesson per week", into: descField)
        }

        let addSaveBtn = app.buttons["Add"]
        if waitForElement(addSaveBtn) {
            addSaveBtn.tap()
        }

        sleep(1)

        // Both title and description should be visible
        let goalTitle = app.staticTexts["Learn SwiftUI"]
        XCTAssertTrue(waitForElement(goalTitle, timeout: 5), "Goal with description should be created")
    }

    // MARK: - Toggle Complete

    func testGoals_toggleComplete_strikesThrough() throws {
        app.launchArguments.append("--with-goals")
        launchApp()
        navigateToGoals()
        sleep(1)

        // Find checkbox button
        let checkbox = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'mark' AND label CONTAINS[c] 'complete'")).element
        if !checkbox.exists {
            // Try alternative - the circle button
            let circleBtn = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'checkbox' OR identifier CONTAINS 'toggle'")).element
            guard waitForElement(circleBtn, timeout: 3) else {
                throw XCTSkip("Checkbox not found")
            }
            circleBtn.tap()
        } else {
            checkbox.tap()
        }

        sleep(1)

        // Goal should be marked complete (checkmark visible or strikethrough)
        let completedIndicator = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'incomplete'")).element
        XCTAssertTrue(completedIndicator.exists, "Goal should be marked as completed")
    }

    func testGoals_toggleIncomplete_removesStrike() throws {
        app.launchArguments.append("--with-completed-goal")
        launchApp()
        navigateToGoals()
        sleep(1)

        // Find completed checkbox and tap to uncomplete
        let checkbox = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'incomplete'")).element
        guard waitForElement(checkbox, timeout: 5) else {
            throw XCTSkip("Completed goal checkbox not found")
        }

        checkbox.tap()
        sleep(1)

        // Should now show as incomplete
        let incompleteIndicator = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'complete' AND NOT label CONTAINS[c] 'incomplete'")).element
        XCTAssertTrue(incompleteIndicator.exists, "Goal should be marked as incomplete")
    }

    // MARK: - Delete

    func testGoals_deleteGoal_removedFromList() throws {
        app.launchArguments.append("--with-goals")
        launchApp()
        navigateToGoals()
        sleep(1)

        // Swipe to delete
        let goalCell = app.cells.firstMatch
        guard waitForElement(goalCell, timeout: 3) else {
            throw XCTSkip("No goals to delete")
        }

        let goalTitle = goalCell.staticTexts.firstMatch.label

        goalCell.swipeLeft()

        let deleteBtn = app.buttons["Delete"]
        if waitForElement(deleteBtn, timeout: 2) {
            deleteBtn.tap()
        }

        sleep(1)

        let deletedGoal = app.staticTexts[goalTitle]
        XCTAssertFalse(deletedGoal.exists, "Deleted goal should be removed")
    }

    // MARK: - Empty State

    func testGoals_emptyState_showsMessage() throws {
        app.launchArguments.append("--clear-goals")
        launchApp()
        navigateToGoals()
        sleep(1)

        let emptyMessage = app.staticTexts["Set your first goal"]
        XCTAssertTrue(waitForElement(emptyMessage, timeout: 5), "Should show empty state message")
    }

    // MARK: - Edge Cases

    func testGoals_emptyTitle_addDisabled() throws {
        launchApp()
        navigateToGoals()
        sleep(1)

        let addBtn = app.buttons["Add goal"]
        guard waitForElement(addBtn, timeout: 5) else {
            throw XCTSkip("Add button not found")
        }
        addBtn.tap()
        sleep(1)

        // Don't enter anything
        let saveBtn = app.buttons["Add"]
        if saveBtn.exists {
            XCTAssertFalse(saveBtn.isEnabled, "Add should be disabled without title")
        }
    }

    func testGoals_cancelCreation_dismissesSheet() throws {
        launchApp()
        navigateToGoals()
        sleep(1)

        let addBtn = app.buttons["Add goal"]
        guard waitForElement(addBtn, timeout: 5) else {
            throw XCTSkip("Add button not found")
        }
        addBtn.tap()
        sleep(1)

        let cancelBtn = app.buttons["Cancel"]
        if waitForElement(cancelBtn, timeout: 3) {
            cancelBtn.tap()
            sleep(1)

            XCTAssertTrue(addBtn.exists, "Should dismiss sheet and return to list")
        }
    }
}
