import SwiftUI

enum Theme {
    static func color(for priority: TaskPriority) -> Color {
        switch priority { case .low: .green; case .medium: .orange; case .high: .red }
    }
    static let cardCornerRadius: CGFloat = 12
}
