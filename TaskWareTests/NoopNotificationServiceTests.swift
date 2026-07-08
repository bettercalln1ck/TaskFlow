import XCTest
@testable import TaskWare

final class NoopNotificationServiceTests: XCTestCase {
    func testNoopDoesNotThrow() async {
        let service = NoopNotificationService()
        await service.requestAuthorization()
        await service.schedule(for: .make(title: "x", now: Date()))
        await service.cancel(for: UUID())
    }
}
