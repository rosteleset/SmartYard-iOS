//
//  PersistenceController.swift
//  SmartYard
//
//  Created by Александр Попов on 23.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Model")

        container.loadPersistentStores { _, error in
            if let error = error {
                Logger.logCritical("Core Data load error: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var context: NSManagedObjectContext { container.viewContext }

    func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            Logger.logError("Ошибка сохранения в CoreData")
        }
    }
}
