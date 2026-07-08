import Foundation

/// Pure search/filter/sort applied over an array of tasks. The Core Data repo
/// mirrors this behavior with predicates/sort descriptors; this is the reference.
enum TaskQueryEngine {
    static func apply(_ query: TaskQuery, to tasks: [TaskItem], now: Date) -> [TaskItem] {
        var result = tasks

        let search = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !search.isEmpty {
            result = result.filter { $0.title.range(of: search, options: .caseInsensitive) != nil }
        }
        if let category = query.category {
            result = result.filter { $0.category == category }
        }
        if let status = query.status {
            result = result.filter { $0.status == status }
        }
        return sort(result, by: query.sort)
    }

    private static func sort(_ tasks: [TaskItem], by sort: TaskSort) -> [TaskItem] {
        switch sort {
        case .dueDateAscending:
            return tasks.sorted { lhs, rhs in compareDueDate(lhs, rhs, ascending: true) }
        case .dueDateDescending:
            return tasks.sorted { lhs, rhs in compareDueDate(lhs, rhs, ascending: false) }
        case .priorityDescending:
            return tasks.sorted { $0.priority > $1.priority }
        case .priorityAscending:
            return tasks.sorted { $0.priority < $1.priority }
        case .recentlyCreated:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        }
    }

    /// nil due dates always sort last regardless of direction.
    private static func compareDueDate(_ lhs: TaskItem, _ rhs: TaskItem, ascending: Bool) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case (nil, nil): return false
        case (nil, _): return false
        case (_, nil): return true
        case let (l?, r?): return ascending ? l < r : l > r
        }
    }
}
