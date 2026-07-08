import Foundation
import UserNotifications

protocol NotificationScheduling: Sendable {
    func requestAuthorization() async
    func schedule(for task: TaskItem) async
    func cancel(for id: UUID) async
}

/// No-op used in tests/previews.
struct NoopNotificationService: NotificationScheduling {
    func requestAuthorization() async {}
    func schedule(for task: TaskItem) async {}
    func cancel(for id: UUID) async {}
}

final class NotificationService: NotificationScheduling, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(for task: TaskItem) async {
        guard let due = task.dueDate, due > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Task due: \(task.title)"
        content.body = task.details.isEmpty ? "This task is due." : task.details
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancel(for id: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
