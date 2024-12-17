//
//  CoreDataManager.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//


import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "FitnessApp")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Ошибка загрузки Core Data: \(error)")
            }
        }
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Ошибка сохранения данных: \(error)")
            }
        }
    }
}
