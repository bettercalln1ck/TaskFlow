import XCTest
@testable import TaskWare

final class InMemoryTaskRepositoryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testCreateFetchUpdateDelete() async throws {
        let repo = InMemoryTaskRepository(now: { self.now })
        let t = TaskItem.make(title: "First", now: now)
        try await repo.create(t)

        var all = try await repo.fetchAll()
        XCTAssertEqual(all.map(\.title), ["First"])

        var edited = t
        edited.title = "First edited"
        try await repo.update(edited)
        let fetched = try await repo.task(with: t.id)
        XCTAssertEqual(fetched?.title, "First edited")

        try await repo.delete(id: t.id)
        all = try await repo.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }

    func testFetchAppliesQuery() async throws {
        let repo = InMemoryTaskRepository(now: { self.now })
        try await repo.create(.make(title: "Work item", now: now, category: .work))
        try await repo.create(.make(title: "Home item", now: now, category: .personal))
        let out = try await repo.fetch(TaskQuery(category: .work))
        XCTAssertEqual(out.map(\.title), ["Work item"])
    }
}
