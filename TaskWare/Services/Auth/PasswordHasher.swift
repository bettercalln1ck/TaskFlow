import Foundation
import CryptoKit

enum PasswordHasher {
    static func hash(_ password: String, salt: String) -> String {
        let data = Data((salt + password).utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
