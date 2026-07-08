import Foundation

enum TaskSort: String, CaseIterable, Sendable, Identifiable {
    case dueDateAscending, dueDateDescending, priorityDescending, priorityAscending, recentlyCreated
    var id: String { rawValue }
    var title: String {
        switch self {
        case .dueDateAscending: "Due date ↑"
        case .dueDateDescending: "Due date ↓"
        case .priorityDescending: "Priority ↓"
        case .priorityAscending: "Priority ↑"
        case .recentlyCreated: "Recently added"
        }
    }
}

struct TaskQuery: Equatable, Sendable {
    var searchText: String = ""
    var category: TaskCategory? = nil
    var status: TaskStatus? = nil
    var sort: TaskSort = .dueDateAscending
}
