import Foundation

protocol AuthStore: Sendable {
    func credential(forEmail email: String) -> StoredCredential?
    func upsert(_ credential: StoredCredential)
    func currentUserID() -> UUID?
    func setCurrentUserID(_ id: UUID?)
    func user(with id: UUID) -> User?
}

/// UserDefaults-backed store. Keyed by lowercased email.
final class UserDefaultsAuthStore: AuthStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let credsKey = "taskware.credentials"
    private let sessionKey = "taskware.session.userID"
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    private func load() -> [String: StoredCredential] {
        guard let data = defaults.data(forKey: credsKey),
              let map = try? JSONDecoder().decode([String: StoredCredential].self, from: data)
        else { return [:] }
        return map
    }
    private func save(_ map: [String: StoredCredential]) {
        defaults.set(try? JSONEncoder().encode(map), forKey: credsKey)
    }

    func credential(forEmail email: String) -> StoredCredential? {
        lock.lock(); defer { lock.unlock() }
        return load()[email.lowercased()]
    }
    func upsert(_ credential: StoredCredential) {
        lock.lock(); defer { lock.unlock() }
        var map = load(); map[credential.user.email.lowercased()] = credential; save(map)
    }
    func user(with id: UUID) -> User? {
        lock.lock(); defer { lock.unlock() }
        return load().values.first { $0.user.id == id }?.user
    }
    func currentUserID() -> UUID? {
        guard let s = defaults.string(forKey: sessionKey) else { return nil }
        return UUID(uuidString: s)
    }
    func setCurrentUserID(_ id: UUID?) {
        defaults.set(id?.uuidString, forKey: sessionKey)
    }
}

/// In-memory store for tests.
final class InMemoryAuthStore: AuthStore, @unchecked Sendable {
    private var creds: [String: StoredCredential] = [:]
    private var session: UUID?
    private let lock = NSLock()
    func credential(forEmail email: String) -> StoredCredential? {
        lock.lock(); defer { lock.unlock() }; return creds[email.lowercased()]
    }
    func upsert(_ credential: StoredCredential) {
        lock.lock(); defer { lock.unlock() }; creds[credential.user.email.lowercased()] = credential
    }
    func user(with id: UUID) -> User? {
        lock.lock(); defer { lock.unlock() }; return creds.values.first { $0.user.id == id }?.user
    }
    func currentUserID() -> UUID? { lock.lock(); defer { lock.unlock() }; return session }
    func setCurrentUserID(_ id: UUID?) { lock.lock(); defer { lock.unlock() }; session = id }
}
