import XCTest
@testable import TaskWare

@MainActor
final class AuthViewModelTests: XCTestCase {
    private func makeVM() -> (AuthViewModel, InMemoryAuthStore) {
        let store = InMemoryAuthStore()
        return (AuthViewModel(authService: LocalAuthService(store: store), authStore: store), store)
    }

    func testSignUpSetsAuthenticatedUser() async {
        let (vm, _) = makeVM()
        vm.email = "a@x.com"; vm.password = "password1"; vm.displayName = "A"
        await vm.signUp()
        XCTAssertNotNil(vm.authenticatedUser)
        XCTAssertNil(vm.errorMessage)
    }

    func testLoginFailureSetsError() async {
        let (vm, _) = makeVM()
        vm.email = "a@x.com"; vm.password = "wrongwrong"
        await vm.login()
        XCTAssertNil(vm.authenticatedUser)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testForgotPasswordSetsInfoMessage() async {
        let (vm, store) = makeVM()
        store.upsert(StoredCredential(user: User(id: UUID(), email: "a@x.com", displayName: "A"),
                                      salt: "s", passwordHash: PasswordHasher.hash("password1", salt: "s")))
        vm.email = "a@x.com"
        await vm.resetPassword()
        XCTAssertNotNil(vm.infoMessage)
        XCTAssertNil(vm.errorMessage)
    }
}
