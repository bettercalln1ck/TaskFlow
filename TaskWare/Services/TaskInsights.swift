import Foundation

struct TaskInsights: Equatable, Sendable {
    var total = 0
    var completed = 0
    var pending = 0
    var overdue = 0
}

enum InsightsCalculator {
    static func insights(for tasks: [TaskItem], asOf now: Date) -> TaskInsights {
        var out = TaskInsights()
        out.total = tasks.count
        for task in tasks {
            if task.isCompleted { out.completed += 1 } else { out.pending += 1 }
            if task.isOverdue(asOf: now) { out.overdue += 1 }
        }
        return out
    }
}
