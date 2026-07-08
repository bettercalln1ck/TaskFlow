import XCTest
@testable import TaskWare

final class InsightsCalculatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testCounts() {
        let tasks: [TaskItem] = [
            .make(title: "a", now: now, dueDate: now.addingTimeInterval(-10), status: .pending),   // overdue
            .make(title: "b", now: now, dueDate: now.addingTimeInterval(10), status: .pending),     // pending, not overdue
            .make(title: "c", now: now, dueDate: now.addingTimeInterval(-10), status: .completed),  // completed (not overdue)
            .make(title: "d", now: now, dueDate: nil, status: .completed),
        ]
        let i = InsightsCalculator.insights(for: tasks, asOf: now)
        XCTAssertEqual(i.total, 4)
        XCTAssertEqual(i.completed, 2)
        XCTAssertEqual(i.pending, 2)
        XCTAssertEqual(i.overdue, 1)
    }
}
