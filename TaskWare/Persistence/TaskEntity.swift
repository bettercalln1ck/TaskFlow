import CoreData

/// Programmatic Core Data model — avoids needing an .xcdatamodeld editor file.
enum TaskModel {
    static let entityName = "TaskEntity"

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        func attr(_ name: String, _ type: NSAttributeType, optional: Bool) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name; a.attributeType = type; a.isOptional = optional
            return a
        }
        entity.properties = [
            attr("id", .UUIDAttributeType, optional: false),
            attr("title", .stringAttributeType, optional: false),
            attr("details", .stringAttributeType, optional: false),
            attr("dueDate", .dateAttributeType, optional: true),
            attr("priority", .integer16AttributeType, optional: false),
            attr("status", .stringAttributeType, optional: false),
            attr("category", .stringAttributeType, optional: false),
            attr("createdAt", .dateAttributeType, optional: false),
            attr("updatedAt", .dateAttributeType, optional: false),
        ]
        // Unique constraint on id.
        entity.uniquenessConstraints = [["id"]]
        model.entities = [entity]
        return model
    }
}
