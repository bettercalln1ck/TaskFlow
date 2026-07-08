import XCTest
@testable import TaskWare

final class DomainEnumTests: XCTestCase {
    func testPriorityIsOrdered() {
        XCTAssertTrue(TaskPriority.low < TaskPriority.medium)
        XCTAssertTrue(TaskPriority.medium < TaskPriority.high)
    }
    func testPriorityAllCases() {
        XCTAssertEqual(TaskPriority.allCases, [.low, .medium, .high])
    }
    func testCategoryHasDisplayMetadata() {
        XCTAssertFalse(TaskCategory.work.title.isEmpty)
        XCTAssertFalse(TaskCategory.work.systemImage.isEmpty)
        XCTAssertEqual(TaskCategory.allCases.count, 5)
    }
    func testStatusTitles() {
        XCTAssertEqual(TaskStatus.pending.title, "Pending")
        XCTAssertEqual(TaskStatus.completed.title, "Completed")
    }
}
