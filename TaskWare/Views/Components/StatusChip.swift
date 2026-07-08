import SwiftUI

struct StatusChip: View {
    let status: TaskStatus
    var isOverdue: Bool = false
    var body: some View {
        let text = isOverdue ? "Overdue" : status.title
        let tint: Color = isOverdue ? .red : (status == .completed ? .green : .secondary)
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}
