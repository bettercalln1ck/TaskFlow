import XCTest
import CoreData
@testable import TaskWare

final class CoreDataStackTests: XCTestCase {
    func testInMemoryStackLoads() {
        let stack = CoreDataStack(inMemory: true)
        XCTAssertNotNil(stack.container.persistentStoreCoordinator.persistentStores.first)
        XCTAssertEqual(stack.container.persistentStoreCoordinator.managedObjectModel.entities.first?.name, "TaskEntity")
    }
}
