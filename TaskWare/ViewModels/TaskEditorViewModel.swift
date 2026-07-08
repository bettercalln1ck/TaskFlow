import Foundation
import Combine

@MainActor
final class TaskEditorViewModel: ObservableObject {
    enum Mode: Equatable {
        case create
        case edit(TaskItem)
        var isEditing: Bool { if case .edit = self { true } else { false } }
    }

    @Published var title: String
    @Published var details: String
    @Published var dueDate: Date?
    @Published var priority: TaskPriority
    @Published var category: TaskCategory
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSaving = false

    let mode: Mode
    private let repository: TaskRepository
    private let notifications: NotificationScheduling
    private let now: @Sendable () -> Date

    init(mode: Mode, repository: TaskRepository,
         notifications: NotificationScheduling, now: @escaping @Sendable () -> Date = { Date() }) {
        self.mode = mode
        self.repository = repository
        self.notifications = notifications
        self.now = now
        switch mode {
        case .create:
            title = ""; details = ""; dueDate = nil; priority = .medium; category = .other
        case .edit(let task):
            title = task.title; details = task.details; dueDate = task.dueDate
            priority = task.priority; category = task.category
        }
    }

    var navigationTitle: String { mode.isEditing ? "Edit Task" : "New Task" }

    @discardableResult
    func save() async -> Bool {
        errorMessage = nil
        let normalizedTitle: String
        do { normalizedTitle = try TaskValidator.validateTitle(title) }
        catch { errorMessage = error.localizedDescription; return false }

        isSaving = true
        defer { isSaving = false }

        let task = buildTask(title: normalizedTitle)
        do {
            switch mode {
            case .create: try await repository.create(task)
            case .edit: try await repository.update(task)
            }
            await scheduleReminderIfNeeded(for: task)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func buildTask(title: String) -> TaskItem {
        switch mode {
        case .create:
            return TaskItem.make(title: title, details: details, now: now(),
                                 dueDate: dueDate, priority: priority, category: category)
        case .edit(let original):
            var updated = original
            updated.title = title; updated.details = details; updated.dueDate = dueDate
            updated.priority = priority; updated.category = category
            return updated
        }
    }

    private func scheduleReminderIfNeeded(for task: TaskItem) async {
        if let due = task.dueDate, due > now(), task.status == .pending {
            await notifications.schedule(for: task)
        } else {
            await notifications.cancel(for: task.id)
        }
    }
}
