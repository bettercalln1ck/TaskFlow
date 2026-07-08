import XCTest
@testable import TaskWare

final class LocalAuthServiceTests: XCTestCase {
    private func makeService() -> (LocalAuthService, InMemoryAuthStore) {
        let store = InMemoryAuthStore()
        return (LocalAuthService(store: store), store)
    }

    func testSignUpThenLogin() async throws {
        let (service, _) = makeService()
        let user = try await service.signUp(email: "A@x.com", password: "password1", displayName: "A")
        XCTAssertEqual(user.email, "a@x.com")
        let loggedIn = try await service.login(email: "a@x.com", password: "password1")
        XCTAssertEqual(loggedIn.id, user.id)
    }

    func testDuplicateEmailRejected() async throws {
        let (service, _) = makeService()
        _ = try await service.signUp(email: "a@x.com", password: "password1", displayName: "A")
        do { _ = try await service.signUp(email: "a@x.com", password: "password2", displayName: "B"); XCTFail() }
        catch { XCTAssertEqual(error as? AuthError, .emailInUse) }
    }

    func testInvalidCredentials() async throws {
        let (service, _) = makeService()
        _ = try await service.signUp(email: "a@x.com", password: "password1", displayName: "A")
        do { _ = try await service.login(email: "a@x.com", password: "wrong"); XCTFail() }
        catch { XCTAssertEqual(error as? AuthError, .invalidCredentials) }
    }

    func testWeakPasswordAndBadEmail() async {
        let (service, _) = makeService()
        do { _ = try await service.signUp(email: "bad", password: "password1", displayName: "A"); XCTFail() }
        catch { XCTAssertEqual(error as? AuthError, .invalidEmail) }
        do { _ = try await service.signUp(email: "a@x.com", password: "123", displayName: "A"); XCTFail() }
        catch { XCTAssertEqual(error as? AuthError, .weakPassword) }
    }

    func testForgotPasswordUnknownEmailThrows() async {
        let (service, _) = makeService()
        do { try await service.requestPasswordReset(email: "nobody@x.com"); XCTFail() }
        catch { XCTAssertEqual(error as? AuthError, .unknownEmail) }
    }
}
