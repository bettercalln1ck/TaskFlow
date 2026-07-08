import XCTest
@testable import TaskWare

@MainActor
final class TaskEditorViewModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testCreateSavesNewTask() async {
        let repo = InMemoryTaskRepository(now: { self.now })
        let vm = TaskEditorViewModel(mode: .create, repository: repo,
                                     notifications: NoopNotificationService(), now: { self.now })
        vm.title = "  New task  "
        vm.priority = .high
        let ok = await vm.save()
        XCTAssertTrue(ok)
        let all = try? await repo.fetchAll()
        XCTAssertEqual(all?.map(\.title), ["New task"])
    }

    func testEmptyTitleShowsValidationError() async {
        let repo = InMemoryTaskRepository(now: { self.now })
        let vm = TaskEditorViewModel(mode: .create, repository: repo,
                                     notifications: NoopNotificationService(), now: { self.now })
        vm.title = "   "
        let ok = await vm.save()
        XCTAssertFalse(ok)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testEditUpdatesExisting() async {
        let repo = InMemoryTaskRepository(now: { self.now })
        let existing = TaskItem.make(title: "Old", now: now)
        try? await repo.create(existing)
        let vm = TaskEditorViewModel(mode: .edit(existing), repository: repo,
                                     notifications: NoopNotificationService(), now: { self.now })
        XCTAssertEqual(vm.title, "Old")
        vm.title = "Updated"
        let ok = await vm.save()
        XCTAssertTrue(ok)
        let fetched = try? await repo.task(with: existing.id)
        XCTAssertEqual(fetched?.title, "Updated")
    }
}
