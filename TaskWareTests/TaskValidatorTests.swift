import XCTest
@testable import TaskWare

final class TaskValidatorTests: XCTestCase {
    func testTrimsAndReturnsTitle() throws {
        XCTAssertEqual(try TaskValidator.validateTitle("  Hello  "), "Hello")
    }
    func testEmptyTitleThrows() {
        XCTAssertThrowsError(try TaskValidator.validateTitle("   ")) { error in
            XCTAssertEqual(error as? TaskValidator.ValidationError, .emptyTitle)
        }
    }
    func testTooLongTitleThrows() {
        let long = String(repeating: "a", count: TaskValidator.maxTitleLength + 1)
        XCTAssertThrowsError(try TaskValidator.validateTitle(long)) { error in
            XCTAssertEqual(error as? TaskValidator.ValidationError,
                           .titleTooLong(max: TaskValidator.maxTitleLength))
        }
    }
}
