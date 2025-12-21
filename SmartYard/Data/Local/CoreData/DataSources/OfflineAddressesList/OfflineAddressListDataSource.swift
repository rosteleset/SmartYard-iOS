//
//  OfflineAddressListDataSource.swift
//  SmartYard
//
//  Created by Александр Попов on 27.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import CoreData

final class OfflineAddressListDataSource {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func importAddresses(_ api: [APIAddress]) {
        let ctx = container.newBackgroundContext()
        ctx.name = "OfflineAddressListDataSource.import"
        ctx.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        ctx.perform { [weak self] in
            guard let self else { return }

            let apiAddressIDs = Set(api.map { $0.houseId })
            deleteAddressNotIn(apiAddressIDs, in: ctx)

            for apiAddress in api {
                let address = upsertAddress(id: apiAddress.houseId, in: ctx)
                address.name = apiAddress.address

                let cachedableDoors = apiAddress.doors.filter { ($0.doorCode ?? "").isEmpty == false }
                let apiDoorIDs = Set(cachedableDoors.map { $0.domophoneId })

                deleteDoorsNotIn(apiDoorIDs, for: address, in: ctx)

                for apiDoor in cachedableDoors {
                    let door = upsertDoor(id: apiDoor.domophoneId, in: ctx)
                    door.address = address
                    door.name = apiDoor.name
                    door.doorCode = apiDoor.doorCode
                }
            }

            do {
                try ctx.save()
            } catch {
                Logger.logError("Import save failed: \(error)")
                ctx.refreshAllObjects()

                do {
                    try ctx.save()
                } catch {
                    Logger.logCritical("Retry import save failed: \(error)")
                }
            }
        }
    }

    private func deleteAddressNotIn(
        _ apiAddressIDs: Set<String>,
        in ctx: NSManagedObjectContext
    ) {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: CachedAddress.entityName)

        if apiAddressIDs.isEmpty {
            req.predicate = NSPredicate(value: true)
        } else {
            req.predicate = NSPredicate(
                format: "NOT (houseId IN %@)",
                apiAddressIDs
            )
        }

        let del = NSBatchDeleteRequest(fetchRequest: req)
        del.resultType = .resultTypeObjectIDs
        
        do {
            let result = try ctx.execute(del) as? NSBatchDeleteResult
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []

            let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
            if apiAddressIDs.isEmpty {
                Logger.logDebug("Deleted ALL addresses (API empty)")
            } else {
                Logger.logDebug("Deleted addresses not in API list (\(apiAddressIDs.count) API IDs)")
            }
        } catch {
            Logger.logWarning("Address cleanup failed: \(error.localizedDescription)")
        }
    }

    private func deleteDoorsNotIn(
        _ apiDoorIDs: Set<String>,
        for address: CachedAddress,
        in ctx: NSManagedObjectContext
    ) {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: CachedDoor.entityName)

        if apiDoorIDs.isEmpty {
            req.predicate = NSPredicate(format: "address = %@", address)
        } else {
            req.predicate = NSPredicate(
                format: "address == %@ AND NOT (domophoneId IN %@)",
                address,
                apiDoorIDs
            )
        }

        let del = NSBatchDeleteRequest(fetchRequest: req)
        del.resultType = .resultTypeObjectIDs
        do {
            let result = try ctx.execute(del) as? NSBatchDeleteResult
            let objectIDs = result?.result as? [NSManagedObjectID] ?? []

            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                into: [container.viewContext]
            )

            Logger.logDebug("✅ Doors cleanup OK for address \(address.houseId ?? "-")")
        } catch {
            Logger.logWarning("⚠️ Delete extra doors failed: \(error)")
        }
    }

    private func upsertAddress(
        id: String,
        in ctx: NSManagedObjectContext
    ) -> CachedAddress {
        do {
            let address = try upsert(
                CachedAddress.self,
                by: "houseId",
                value: id,
                in: ctx
            )
            Logger.logDebug("Upsert Address OK (houseId=\(id))")
            return address
        } catch {
            Logger.logError("Upsert Address FAILED (houseId=\(id)) – \(error.localizedDescription)")
            let address = CachedAddress(context: ctx)
            address.setValue(id, forKey: "houseId")
            return address
        }
    }

    private func upsertDoor(
        id: String,
        in ctx: NSManagedObjectContext
    ) -> CachedDoor {
        do {
            let door = try upsert(
                CachedDoor.self,
                by: "domophoneId",
                value: id,
                in: ctx
            )
            Logger.logDebug("Upsert Door OK (domophoneId=\(id))")
            return door
        } catch {
            Logger.logError("Upsert Door FAILED (domophoneId=\(id)) – \(error.localizedDescription)")
            let door = CachedDoor(context: ctx)
            door.setValue(id, forKey: "domophoneId")
            return door
        }
    }

    func wipeCache() throws {
        let ctx = container.newBackgroundContext()
        ctx.performAndWait {
            let doorReq = NSFetchRequest<NSFetchRequestResult>(entityName: CachedDoor.entityName)
            let addrReq = NSFetchRequest<NSFetchRequestResult>(entityName: CachedAddress.entityName)
            _ = try? ctx.execute(NSBatchDeleteRequest(fetchRequest: doorReq))
            _ = try? ctx.execute(NSBatchDeleteRequest(fetchRequest: addrReq))
        }
    }

}

// MARK: - Helpers

extension OfflineAddressListDataSource {

    @discardableResult
    private func upsert<T: NSManagedObject & ManagedEntity>(
        _ type: T.Type,
        by key: String,
        value: String,
        in ctx: NSManagedObjectContext,
        configure: ((T) -> Void)? = nil
    ) throws -> T {
        if let existing = try fetchOne(type, by: key, value: value, in: ctx) {
            configure?(existing)
            return existing
        } else {
            let obj = T(context: ctx)
            obj.setValue(value, forKey: key)
            configure?(obj)
            return obj
        }
    }

    private func fetchOne<T: NSManagedObject & ManagedEntity>(
        _ type: T.Type,
        by key: String,
        value: String,
        in ctx: NSManagedObjectContext
    ) throws -> T? {
        let rqst = NSFetchRequest<T>(entityName: type.entityName)
        rqst.fetchLimit = 1; rqst.predicate = NSPredicate(format: "%K == %@", key, value)
        return try ctx.fetch(rqst).first
    }

}

extension OfflineAddressListDataSource {
    func fetchOfflineAddresses() throws -> [OfflineAddress] {
        let ctx = container.viewContext
        let req: NSFetchRequest<CachedAddress> = CachedAddress.fetchRequest()

        let cached = try ctx.fetch(req)

        return cached.map { addr in
            let doors = addr.doorsSet
                .compactMap { door -> OfflineDoor? in
                    guard
                        let domophoneId = door.domophoneId,
                        let name = door.name,
                        let code = door.doorCode,
                        !code.isEmpty
                    else { return nil }

                    return OfflineDoor(domophoneId: domophoneId, name: name, code: code)
                }

            return OfflineAddress(
                houseId: addr.houseId ?? "",
                address: addr.name ?? "",
                doors: doors
            )
        }
        .filter { !$0.houseId.isEmpty } 
    }
}
