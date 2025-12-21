//
//  CachedAddress+CoreDataProperties.swift
//  
//
//  Created by Александр Попов on 03.11.2025.
//
//

import Foundation
import CoreData

final class CachedAddress: NSManagedObject, ManagedEntity {
    @NSManaged var houseId: String?
    @NSManaged var name: String?
    @NSManaged var doors: NSSet?

    @nonobjc
    static func fetchRequest() -> NSFetchRequest<CachedAddress> {
        return NSFetchRequest<CachedAddress>(entityName: CachedAddress.entityName)
    }
}

// MARK: Generated accessors for doors
// swiftlint:disable attributes
extension CachedAddress {

    @objc(addDoorsObject:)
    @NSManaged func addToDoors(_ value: CachedDoor)

    @objc(removeDoorsObject:)
    @NSManaged func removeFromDoors(_ value: CachedDoor)

    @objc(addDoors:)
    @NSManaged func addToDoors(_ values: NSSet)

    @objc(removeDoors:)
    @NSManaged func removeFromDoors(_ values: NSSet)

}
// swiftlint:enable attributes

// MARK: - Swift-friendly helpers
extension CachedAddress {

    /// Strongly-typed Swift Set wrapper around the Obj-C-backed `doors` relation.
    var doorsSet: Set<CachedDoor> {
        get { (doors as? Set<CachedDoor>) ?? [] }
        set { doors = NSSet(set: newValue) }
    }

    /// Add a single door using a Swift API.
    func add(door: CachedDoor) {
        addToDoors(door)
    }

    /// Add multiple doors using a Swift API.
    func add(doors newDoors: [CachedDoor]) {
        addToDoors(NSSet(array: newDoors))
    }

    /// Remove a single door using a Swift API.
    func remove(door: CachedDoor) {
        removeFromDoors(door)
    }

    /// Remove multiple doors using a Swift API.
    func remove(doors removed: [CachedDoor]) {
        removeFromDoors(NSSet(array: removed))
    }
}
