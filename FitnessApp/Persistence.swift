//
//  Persistence.swift
//  FitnessApp
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitnessApp")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically  = true
            description.shouldInferMappingModelAutomatically = true
        }

        let coordinator = container.persistentStoreCoordinator
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Migration failed — destroy old store and start fresh
                if let storeURL = storeDescription.url {
                    try? coordinator.destroyPersistentStore(
                        at: storeURL, ofType: NSSQLiteStoreType, options: nil)
                    try? coordinator.addPersistentStore(
                        ofType: NSSQLiteStoreType, configurationName: nil,
                        at: storeURL, options: nil)
                }
                print("⚠️ CoreData migration failed, store reset: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        try? ctx.save()
    }
}
