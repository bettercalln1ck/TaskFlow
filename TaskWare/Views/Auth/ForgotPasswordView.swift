import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(footer: Text("This is a mock flow — no email is actually sent.")) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never).keyboardType(.emailAddress)
                }
                if let info = viewModel.infoMessage { Text(info).foregroundStyle(.green).font(.footnote) }
                if let error = viewModel.errorMessage { Text(error).foregroundStyle(.red).font(.footnote) }
                Button("Send reset instructions") { Task { await viewModel.resetPassword() } }
                    .disabled(viewModel.isBusy)
            }
            .navigationTitle("Reset Password")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}
