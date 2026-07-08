import XCTest
@testable import TaskWare

final class TaskItemTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFactoryMakesPendingTaskWithTimestamps() {
        let t = TaskItem.make(title: "Buy milk", now: now)
        XCTAssertEqual(t.title, "Buy milk")
        XCTAssertEqual(t.status, .pending)
        XCTAssertEqual(t.createdAt, now)
        XCTAssertEqual(t.updatedAt, now)
        XCTAssertEqual(t.priority, .medium)
        XCTAssertEqual(t.category, .other)
    }

    func testDuplicateResetsIdentityStatusAndTimestamps() {
        let original = TaskItem.make(title: "Report", now: now, status: .completed)
        let newDate = now.addingTimeInterval(500)
        let copy = original.duplicated(id: UUID(), now: newDate)

        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.title, "Report (copy)")
        XCTAssertEqual(copy.status, .pending)
        XCTAssertEqual(copy.createdAt, newDate)
        XCTAssertEqual(copy.updatedAt, newDate)
        XCTAssertEqual(copy.priority, original.priority)
        XCTAssertEqual(copy.category, original.category)
    }

    func testOverdueOnlyWhenPendingAndPastDue() {
        let due = now
        let overdue = TaskItem.make(title: "x", now: now, dueDate: due, status: .pending)
        XCTAssertTrue(overdue.isOverdue(asOf: now.addingTimeInterval(1)))
        XCTAssertFalse(overdue.isOverdue(asOf: now.addingTimeInterval(-1)))

        let done = TaskItem.make(title: "y", now: now, dueDate: due, status: .completed)
        XCTAssertFalse(done.isOverdue(asOf: now.addingTimeInterval(1000)))

        let noDue = TaskItem.make(title: "z", now: now, dueDate: nil, status: .pending)
        XCTAssertFalse(noDue.isOverdue(asOf: now.addingTimeInterval(1000)))
    }
}
