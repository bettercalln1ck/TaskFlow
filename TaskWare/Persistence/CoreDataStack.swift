import CoreData

// ponytail: nonisolated so deinit runs off the main actor — default-MainActor
// isolation otherwise schedules deinit on the executor and double-frees at runtime.
nonisolated final class CoreDataStack: @unchecked Sendable {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TaskWare", managedObjectModel: TaskModel.makeModel())
        if inMemory {
            // ponytail: /dev/null SQLite store is Apple's current in-memory pattern;
            // NSInMemoryStoreType is deprecated and crashes (double-free) on this runtime.
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data store failed to load: \(error)") }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
