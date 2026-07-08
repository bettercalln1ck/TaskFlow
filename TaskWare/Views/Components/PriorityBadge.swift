import SwiftUI

struct PriorityBadge: View {
    let priority: TaskPriority
    var body: some View {
        Text(priority.title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Theme.color(for: priority).opacity(0.15), in: Capsule())
            .foregroundStyle(Theme.color(for: priority))
            .accessibilityLabel("Priority \(priority.title)")
    }
}
