import Foundation

protocol TaskRepository: Sendable {
    func fetchAll() async throws -> [TaskItem]
    func fetch(_ query: TaskQuery) async throws -> [TaskItem]
    func task(with id: UUID) async throws -> TaskItem?
    func create(_ task: TaskItem) async throws
    func update(_ task: TaskItem) async throws
    func delete(id: UUID) async throws
}
