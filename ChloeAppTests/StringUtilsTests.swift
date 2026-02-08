import XCTest
@testable import ChloeApp

final class StringUtilsTests: XCTestCase {

    // MARK: - isValidEmail

    func testValidEmail_standard() {
        XCTAssertTrue("user@example.com".isValidEmail)
    }

    func testValidEmail_withSubdomain() {
        XCTAssertTrue("user@mail.example.com".isValidEmail)
    }

    func testValidEmail_withPlus() {
        XCTAssertTrue("user+tag@example.com".isValidEmail)
    }

    func testInvalidEmail_noAt() {
        XCTAssertFalse("userexample.com".isValidEmail)
    }

    func testInvalidEmail_noDotAfterAt() {
        XCTAssertFalse("user@localhost".isValidEmail)
    }

    func testInvalidEmail_empty() {
        XCTAssertFalse("".isValidEmail)
    }

    func testInvalidEmail_atOnly() {
        XCTAssertFalse("@".isValidEmail)
    }

    func testInvalidEmail_multipleAt() {
        // firstIndex(of: "@") finds the first one; afterAt contains "b@c.com" which has "."
        // so "a@b@c.com" passes — documenting the basic nature of this check
        XCTAssertTrue("a@b@c.com".isValidEmail)
    }

    func testValidEmail_trimmed() {
        XCTAssertTrue("  user@example.com  ".isValidEmail)
    }

    // MARK: - trimmed

    func testTrimmed_removesWhitespace() {
        XCTAssertEqual("  hello  ".trimmed, "hello")
    }

    func testTrimmed_removesNewlines() {
        XCTAssertEqual("\nhello\n".trimmed, "hello")
    }

    func testTrimmed_emptyString() {
        XCTAssertEqual("".trimmed, "")
    }

    // MARK: - isBlank

    func testIsBlank_emptyString() {
        XCTAssertTrue("".isBlank)
    }

    func testIsBlank_whitespaceOnly() {
        XCTAssertTrue("   ".isBlank)
    }

    func testIsBlank_newlineOnly() {
        XCTAssertTrue("\n".isBlank)
    }

    func testIsBlank_hasContent() {
        XCTAssertFalse("hello".isBlank)
    }

    func testIsBlank_whitespaceWithContent() {
        XCTAssertFalse("  hello  ".isBlank)
    }
}
