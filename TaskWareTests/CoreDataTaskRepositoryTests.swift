import XCTest
import CoreData
@testable import TaskWare

final class CoreDataTaskRepositoryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let owner = UUID()
    private var repo: CoreDataTaskRepository!

    override func setUp() {
        super.setUp()
        repo = CoreDataTaskRepository(stack: CoreDataStack(inMemory: true), now: { self.now })
    }

    func testCreateAndFetchAll() async throws {
        try await repo.create(.make(title: "Persisted", now: now, userID: owner))
        let all = try await repo.fetchAll(for: owner)
        XCTAssertEqual(all.map(\.title), ["Persisted"])
    }

    func testUpdateAndDelete() async throws {
        let t = TaskItem.make(title: "Edit me", now: now, userID: owner)
        try await repo.create(t)
        var edited = t; edited.title = "Edited"; edited.status = .completed
        try await repo.update(edited)
        let updated = try await repo.task(with: t.id)
        XCTAssertEqual(updated?.status, .completed)
        try await repo.delete(id: t.id)
        let deleted = try await repo.task(with: t.id)
        XCTAssertNil(deleted)
    }

    func testTasksAreScopedToOwner() async throws {
        let ownerA = UUID(), ownerB = UUID()
        try await repo.create(.make(title: "A's task", now: now, userID: ownerA))
        try await repo.create(.make(title: "B's task", now: now, userID: ownerB))

        let a = try await repo.fetchAll(for: ownerA)
        XCTAssertEqual(a.map(\.title), ["A's task"])
        let b = try await repo.fetchAll(for: ownerB)
        XCTAssertEqual(b.map(\.title), ["B's task"])
    }

    func testFetchWithQueryFiltersAndSorts() async throws {
        try await repo.create(.make(title: "Work high", now: now,
            dueDate: now.addingTimeInterval(200), priority: .high, category: .work, userID: owner))
        try await repo.create(.make(title: "Work low", now: now,
            dueDate: now.addingTimeInterval(100), priority: .low, category: .work, userID: owner))
        try await repo.create(.make(title: "Personal", now: now, category: .personal, userID: owner))

        let byCategory = try await repo.fetch(TaskQuery(category: .work, sort: .dueDateAscending), for: owner)
        XCTAssertEqual(byCategory.map(\.title), ["Work low", "Work high"])

        let bySearch = try await repo.fetch(TaskQuery(searchText: "personal"), for: owner)
        XCTAssertEqual(bySearch.map(\.title), ["Personal"])
    }
}
