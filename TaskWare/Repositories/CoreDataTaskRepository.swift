import CoreData

nonisolated final class CoreDataTaskRepository: TaskRepository, @unchecked Sendable {
    private let stack: CoreDataStack
    private let now: @Sendable () -> Date

    init(stack: CoreDataStack, now: @escaping @Sendable () -> Date = { Date() }) {
        self.stack = stack
        self.now = now
    }

    func fetchAll() async throws -> [TaskItem] { try await fetch(TaskQuery()) }

    func fetch(_ query: TaskQuery) async throws -> [TaskItem] {
        try await perform { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: TaskModel.entityName)
            request.predicate = Self.predicate(for: query)
            request.sortDescriptors = Self.sortDescriptors(for: query.sort)
            return try context.fetch(request).map(Self.item(from:))
        }
    }

    func task(with id: UUID) async throws -> TaskItem? {
        try await perform { context in
            try Self.object(with: id, in: context).map(Self.item(from:))
        }
    }

    func create(_ task: TaskItem) async throws {
        try await perform { context in
            let object = NSEntityDescription.insertNewObject(forEntityName: TaskModel.entityName, into: context)
            Self.apply(task, to: object)
            try context.save()
        }
    }

    func update(_ task: TaskItem) async throws {
        let stamp = now()
        try await perform { context in
            guard let object = try Self.object(with: task.id, in: context) else { return }
            var updated = task; updated.updatedAt = stamp
            Self.apply(updated, to: object)
            try context.save()
        }
    }

    func delete(id: UUID) async throws {
        try await perform { context in
            guard let object = try Self.object(with: id, in: context) else { return }
            context.delete(object)
            try context.save()
        }
    }

    // MARK: - Helpers

    private func perform<T: Sendable>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        let container = stack.container
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                do { continuation.resume(returning: try block(context)) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private static func object(with id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: TaskModel.entityName)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private static func predicate(for query: TaskQuery) -> NSPredicate? {
        var predicates: [NSPredicate] = []
        let search = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !search.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", search))
        }
        if let category = query.category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        if let status = query.status {
            predicates.append(NSPredicate(format: "status == %@", status.rawValue))
        }
        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private static func sortDescriptors(for sort: TaskSort) -> [NSSortDescriptor] {
        switch sort {
        case .dueDateAscending:
            return [NSSortDescriptor(key: "dueDate", ascending: true)]
        case .dueDateDescending:
            return [NSSortDescriptor(key: "dueDate", ascending: false)]
        case .priorityDescending:
            return [NSSortDescriptor(key: "priority", ascending: false)]
        case .priorityAscending:
            return [NSSortDescriptor(key: "priority", ascending: true)]
        case .recentlyCreated:
            return [NSSortDescriptor(key: "createdAt", ascending: false)]
        }
    }

    private static func apply(_ task: TaskItem, to object: NSManagedObject) {
        object.setValue(task.id, forKey: "id")
        object.setValue(task.title, forKey: "title")
        object.setValue(task.details, forKey: "details")
        object.setValue(task.dueDate, forKey: "dueDate")
        object.setValue(task.priority.rawValue, forKey: "priority")
        object.setValue(task.status.rawValue, forKey: "status")
        object.setValue(task.category.rawValue, forKey: "category")
        object.setValue(task.createdAt, forKey: "createdAt")
        object.setValue(task.updatedAt, forKey: "updatedAt")
    }

    private static func item(from object: NSManagedObject) -> TaskItem {
        TaskItem(
            id: object.value(forKey: "id") as! UUID,
            title: object.value(forKey: "title") as! String,
            details: object.value(forKey: "details") as! String,
            dueDate: object.value(forKey: "dueDate") as? Date,
            priority: TaskPriority(rawValue: object.value(forKey: "priority") as! Int16) ?? .medium,
            status: TaskStatus(rawValue: object.value(forKey: "status") as! String) ?? .pending,
            category: TaskCategory(rawValue: object.value(forKey: "category") as! String) ?? .other,
            createdAt: object.value(forKey: "createdAt") as! Date,
            updatedAt: object.value(forKey: "updatedAt") as! Date
        )
    }
}
