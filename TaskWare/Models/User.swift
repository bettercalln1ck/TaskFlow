import Foundation

struct User: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let email: String
    var displayName: String
}

/// Persisted credential record (local only; not production-secure).
struct StoredCredential: Equatable, Sendable, Codable {
    var user: User
    var salt: String
    var passwordHash: String
}
