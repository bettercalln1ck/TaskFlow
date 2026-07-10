import Foundation

actor InMemoryTaskRepository: TaskRepository {
    private var storage: [UUID: TaskItem] = [:]
    private let now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date = { Date() }, seed: [TaskItem] = []) {
        self.now = now
        for task in seed { storage[task.id] = task }
    }

    func fetchAll(for ownerID: UUID) async throws -> [TaskItem] {
        try await fetch(TaskQuery(), for: ownerID)
    }
    func fetch(_ query: TaskQuery, for ownerID: UUID) async throws -> [TaskItem] {
        let owned = storage.values.filter { $0.userID == ownerID }
        return TaskQueryEngine.apply(query, to: Array(owned), now: now())
    }
    func task(with id: UUID) async throws -> TaskItem? { storage[id] }
    func create(_ task: TaskItem) async throws { storage[task.id] = task }
    func update(_ task: TaskItem) async throws {
        var updated = task
        updated.updatedAt = now()
        storage[task.id] = updated
    }
    func delete(id: UUID) async throws { storage[id] = nil }
}
