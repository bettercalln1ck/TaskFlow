import XCTest
@testable import TaskWare

final class TaskQueryEngineTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private lazy var tasks: [TaskItem] = [
        .make(title: "Alpha report", now: now, dueDate: now.addingTimeInterval(300),
              priority: .high, status: .pending, category: .work),
        .make(title: "Buy groceries", now: now, dueDate: now.addingTimeInterval(100),
              priority: .low, status: .pending, category: .shopping),
        .make(title: "Alpha review", now: now, dueDate: nil,
              priority: .medium, status: .completed, category: .work),
    ]

    func testSearchByTitleCaseInsensitive() {
        let q = TaskQuery(searchText: "alpha")
        let out = TaskQueryEngine.apply(q, to: tasks, now: now)
        XCTAssertEqual(out.count, 2)
    }
    func testFilterByCategoryAndStatus() {
        let q = TaskQuery(category: .work, status: .pending)
        let out = TaskQueryEngine.apply(q, to: tasks, now: now)
        XCTAssertEqual(out.map(\.title), ["Alpha report"])
    }
    func testSortByDueDateAscendingNilsLast() {
        let q = TaskQuery(sort: .dueDateAscending)
        let out = TaskQueryEngine.apply(q, to: tasks, now: now)
        XCTAssertEqual(out.map(\.title), ["Buy groceries", "Alpha report", "Alpha review"])
    }
    func testSortByPriorityDescending() {
        let q = TaskQuery(sort: .priorityDescending)
        let out = TaskQueryEngine.apply(q, to: tasks, now: now)
        XCTAssertEqual(out.first?.title, "Alpha report") // high first
    }
}
