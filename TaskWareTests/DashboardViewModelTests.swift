import XCTest
@testable import TaskWare

@MainActor
final class DashboardViewModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeVM(seed: [TaskItem] = []) -> DashboardViewModel {
        let repo = InMemoryTaskRepository(now: { self.now }, seed: seed)
        return DashboardViewModel(repository: repo,
                                  notifications: NoopNotificationService(),
                                  now: { self.now })
    }

    func testLoadEmptyShowsEmptyState() async {
        let vm = makeVM()
        await vm.load()
        XCTAssertEqual(vm.state, .empty)
        XCTAssertEqual(vm.insights.total, 0)
    }

    func testLoadPopulatesTasksAndInsights() async {
        let vm = makeVM(seed: [
            .make(title: "A", now: now, status: .completed),
            .make(title: "B", now: now, dueDate: now.addingTimeInterval(-1), status: .pending),
        ])
        await vm.load()
        XCTAssertEqual(vm.tasks.count, 2)
        XCTAssertEqual(vm.insights.completed, 1)
        XCTAssertEqual(vm.insights.overdue, 1)
        if case .loaded = vm.state {} else { XCTFail("expected loaded") }
    }

    func testToggleComplete() async {
        let t = TaskItem.make(title: "A", now: now, status: .pending)
        let vm = makeVM(seed: [t])
        await vm.load()
        await vm.toggleComplete(t)
        XCTAssertEqual(vm.tasks.first?.status, .completed)
    }

    func testDeleteThenUndoRestores() async {
        let t = TaskItem.make(title: "A", now: now)
        let vm = makeVM(seed: [t])
        await vm.load()
        await vm.delete(t)
        XCTAssertTrue(vm.tasks.isEmpty)
        await vm.undoLastDelete()
        XCTAssertEqual(vm.tasks.map(\.title), ["A"])
    }

    func testDuplicateAddsCopy() async {
        let t = TaskItem.make(title: "A", now: now)
        let vm = makeVM(seed: [t])
        await vm.load()
        await vm.duplicate(t)
        XCTAssertEqual(vm.tasks.count, 2)
        XCTAssertTrue(vm.tasks.contains { $0.title == "A (copy)" })
    }

    func testSearchFilters() async {
        let vm = makeVM(seed: [
            .make(title: "Apple", now: now), .make(title: "Banana", now: now),
        ])
        await vm.load()
        vm.query.searchText = "app"
        await vm.applyQuery()
        XCTAssertEqual(vm.tasks.map(\.title), ["Apple"])
    }
}
