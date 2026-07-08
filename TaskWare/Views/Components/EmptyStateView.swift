import SwiftUI

struct EmptyStateView: View {
    var title = "No tasks yet"
    var message = "Tap + to create your first task."
    var systemImage = "checklist"
    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}
