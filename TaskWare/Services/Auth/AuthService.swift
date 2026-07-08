import Foundation

enum AuthError: LocalizedError, Equatable {
    case invalidEmail, weakPassword, emailInUse, invalidCredentials, unknownEmail

    var errorDescription: String? {
        switch self {
        case .invalidEmail: "Enter a valid email address."
        case .weakPassword: "Password must be at least 6 characters."
        case .emailInUse: "An account with that email already exists."
        case .invalidCredentials: "Incorrect email or password."
        case .unknownEmail: "No account found for that email."
        }
    }
}

protocol AuthService: Sendable {
    @discardableResult func signUp(email: String, password: String, displayName: String) async throws -> User
    @discardableResult func login(email: String, password: String) async throws -> User
    func requestPasswordReset(email: String) async throws
}
