import SwiftUI

struct UndoSnackbar: View {
    let message: String
    let onUndo: () -> Void
    var body: some View {
        HStack {
            Text(message).foregroundStyle(.white)
            Spacer()
            Button("Undo", action: onUndo).font(.headline).foregroundStyle(.yellow)
        }
        .padding()
        .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
