import Foundation

struct TaskItem: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var title: String
    var details: String
    var dueDate: Date?
    var priority: TaskPriority
    var status: TaskStatus
    var category: TaskCategory
    var createdAt: Date
    var updatedAt: Date

    var isCompleted: Bool { status == .completed }

    func isOverdue(asOf now: Date) -> Bool {
        guard status == .pending, let dueDate else { return false }
        return dueDate < now
    }

    /// Convenience factory used by the app and tests.
    static func make(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        now: Date,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        status: TaskStatus = .pending,
        category: TaskCategory = .other
    ) -> TaskItem {
        TaskItem(id: id, title: title, details: details, dueDate: dueDate,
                 priority: priority, status: status, category: category,
                 createdAt: now, updatedAt: now)
    }

    /// A fresh, pending copy suitable for the "Duplicate" action.
    func duplicated(id: UUID = UUID(), now: Date) -> TaskItem {
        TaskItem(id: id, title: "\(title) (copy)", details: details, dueDate: dueDate,
                 priority: priority, status: .pending, category: category,
                 createdAt: now, updatedAt: now)
    }
}
