import Foundation

enum DebugSeeder {
    static func seed(_ count: Int, ownerID: UUID, into repository: TaskRepository, now: Date) async {
        for i in 0..<count {
            let task = TaskItem.make(
                title: "Task #\(i)",
                details: "Auto-generated task \(i)",
                now: now,
                dueDate: now.addingTimeInterval(Double(i % 30 - 10) * 86_400),
                priority: TaskPriority.allCases[i % 3],
                status: i % 4 == 0 ? .completed : .pending,
                category: TaskCategory.allCases[i % TaskCategory.allCases.count],
                userID: ownerID
            )
            try? await repository.create(task)
        }
    }
}
