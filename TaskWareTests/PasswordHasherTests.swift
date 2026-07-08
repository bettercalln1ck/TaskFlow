import XCTest
@testable import TaskWare

final class PasswordHasherTests: XCTestCase {
    func testHashIsStableAndSaltSensitive() {
        let a = PasswordHasher.hash("secret", salt: "s1")
        XCTAssertEqual(a, PasswordHasher.hash("secret", salt: "s1"))
        XCTAssertNotEqual(a, PasswordHasher.hash("secret", salt: "s2"))
        XCTAssertNotEqual(a, PasswordHasher.hash("other", salt: "s1"))
    }
}
