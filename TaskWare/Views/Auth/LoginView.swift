import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showForgot = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }
                Section {
                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        HStack { Spacer(); if viewModel.isBusy { ProgressView() } else { Text("Log In") }; Spacer() }
                    }
                    .disabled(viewModel.isBusy)
                    Button("Forgot password?") { showForgot = true }
                        .font(.footnote)
                }
                Section {
                    Button("Create an account") { showSignUp = true }
                }
            }
            .navigationTitle("TaskWare")
            .sheet(isPresented: $showSignUp) { SignUpView(viewModel: viewModel) }
            .sheet(isPresented: $showForgot) { ForgotPasswordView(viewModel: viewModel) }
        }
    }
}
