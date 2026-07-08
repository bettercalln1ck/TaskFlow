import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display name", text: $viewModel.displayName)
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never).keyboardType(.emailAddress)
                    SecureField("Password (min 6 chars)", text: $viewModel.password)
                }
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }
                Button {
                    Task { await viewModel.signUp(); if viewModel.authenticatedUser != nil { dismiss() } }
                } label: {
                    HStack { Spacer(); if viewModel.isBusy { ProgressView() } else { Text("Sign Up") }; Spacer() }
                }
                .disabled(viewModel.isBusy)
            }
            .navigationTitle("Create Account")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
