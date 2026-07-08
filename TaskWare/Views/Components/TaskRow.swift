import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    let now: Date
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark as pending" : "Mark as completed")

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                if !task.details.isEmpty {
                    Text(task.details).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                HStack(spacing: 8) {
                    Label(task.category.title, systemImage: task.category.systemImage)
                        .font(.caption2).foregroundStyle(.secondary)
                    PriorityBadge(priority: task.priority)
                    StatusChip(status: task.status, isOverdue: task.isOverdue(asOf: now))
                    if let due = task.dueDate {
                        Text(due, format: .dateTime.month().day())
                            .font(.caption2).foregroundStyle(task.isOverdue(asOf: now) ? .red : .secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
