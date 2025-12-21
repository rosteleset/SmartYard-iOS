//
//  CachedDoor+CoreDataProperties.swift
//  
//
//  Created by Александр Попов on 03.11.2025.
//
//

import Foundation
import CoreData

final class CachedDoor: NSManagedObject, ManagedEntity {
    @NSManaged var domophoneId: String?
    @NSManaged var name: String?
    @NSManaged var doorCode: String?

    // relationship
    @NSManaged var address: CachedAddress?

    @nonobjc
    static func fetchRequest() -> NSFetchRequest<CachedDoor> {
        return NSFetchRequest<CachedDoor>(entityName: CachedDoor.entityName)
    }
}
