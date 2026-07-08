import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[TaskItem]> = .idle
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var insights = TaskInsights()
    @Published var query = TaskQuery()
    @Published var recentlyDeleted: TaskItem?

    private let repository: TaskRepository
    private let notifications: NotificationScheduling
    private let now: @Sendable () -> Date

    init(repository: TaskRepository,
         notifications: NotificationScheduling,
         now: @escaping @Sendable () -> Date = { Date() }) {
        self.repository = repository
        self.notifications = notifications
        self.now = now
    }

    func load() async {
        state = .loading
        await reload()
    }

    func refresh() async { await reload() }

    func applyQuery() async { await reload() }

    private func reload() async {
        do {
            let fetched = try await repository.fetch(query)
            let all = try await repository.fetchAll()
            tasks = fetched
            insights = InsightsCalculator.insights(for: all, asOf: now())
            state = fetched.isEmpty
                ? (query == TaskQuery() ? .empty : .loaded([]))
                : .loaded(fetched)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleComplete(_ task: TaskItem) async {
        var updated = task
        updated.status = task.isCompleted ? .pending : .completed
        do {
            try await repository.update(updated)
            if updated.isCompleted { await notifications.cancel(for: updated.id) }
            await reload()
        } catch { state = .failed(error.localizedDescription) }
    }

    func duplicate(_ task: TaskItem) async {
        do { try await repository.create(task.duplicated(now: now())); await reload() }
        catch { state = .failed(error.localizedDescription) }
    }

    func delete(_ task: TaskItem) async {
        do {
            try await repository.delete(id: task.id)
            await notifications.cancel(for: task.id)
            recentlyDeleted = task
            await reload()
        } catch { state = .failed(error.localizedDescription) }
    }

    func undoLastDelete() async {
        guard let task = recentlyDeleted else { return }
        recentlyDeleted = nil
        do { try await repository.create(task); await reload() }
        catch { state = .failed(error.localizedDescription) }
    }

    func clearUndo() { recentlyDeleted = nil }
}
