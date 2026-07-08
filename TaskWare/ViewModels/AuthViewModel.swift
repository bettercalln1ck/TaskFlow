import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published private(set) var isBusy = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var infoMessage: String?
    @Published private(set) var authenticatedUser: User?

    private let authService: AuthService
    private let authStore: AuthStore

    init(authService: AuthService, authStore: AuthStore) {
        self.authService = authService
        self.authStore = authStore
    }

    /// Restores a persisted session at launch.
    func restoreSession() {
        if let id = authStore.currentUserID(), let user = authStore.user(with: id) {
            authenticatedUser = user
        }
    }

    func login() async { await run { try await self.authService.login(email: self.email, password: self.password) } }
    func signUp() async {
        await run { try await self.authService.signUp(email: self.email, password: self.password, displayName: self.displayName) }
    }

    func resetPassword() async {
        errorMessage = nil; infoMessage = nil; isBusy = true; defer { isBusy = false }
        do {
            try await authService.requestPasswordReset(email: email)
            infoMessage = "If an account exists, we’ve sent reset instructions."
        } catch { errorMessage = error.localizedDescription }
    }

    func logout() {
        authStore.setCurrentUserID(nil)
        authenticatedUser = nil
        email = ""; password = ""; displayName = ""
    }

    private func run(_ operation: @escaping () async throws -> User) async {
        errorMessage = nil; infoMessage = nil; isBusy = true; defer { isBusy = false }
        do { authenticatedUser = try await operation() }
        catch { errorMessage = error.localizedDescription }
    }
}
