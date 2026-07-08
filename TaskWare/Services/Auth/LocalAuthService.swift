import Foundation

final class LocalAuthService: AuthService, @unchecked Sendable {
    private let store: AuthStore
    init(store: AuthStore) { self.store = store }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let email = normalize(email)
        try validate(email: email, password: password)
        guard store.credential(forEmail: email) == nil else { throw AuthError.emailInUse }
        let salt = UUID().uuidString
        let user = User(id: UUID(), email: email,
                        displayName: displayName.isEmpty ? email : displayName)
        store.upsert(StoredCredential(user: user, salt: salt,
                                      passwordHash: PasswordHasher.hash(password, salt: salt)))
        store.setCurrentUserID(user.id)
        return user
    }

    func login(email: String, password: String) async throws -> User {
        let email = normalize(email)
        guard let cred = store.credential(forEmail: email) else { throw AuthError.invalidCredentials }
        guard cred.passwordHash == PasswordHasher.hash(password, salt: cred.salt) else {
            throw AuthError.invalidCredentials
        }
        store.setCurrentUserID(cred.user.id)
        return cred.user
    }

    func requestPasswordReset(email: String) async throws {
        // Mock: verify the account exists; a real app would send an email.
        guard store.credential(forEmail: normalize(email)) != nil else { throw AuthError.unknownEmail }
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    private func validate(email: String, password: String) throws {
        guard email.contains("@"), email.contains("."), !email.hasPrefix("@") else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else { throw AuthError.weakPassword }
    }
}
