import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: { Text(message) } actions: {
            Button("Try Again", action: retry).buttonStyle(.borderedProminent)
        }
    }
}
