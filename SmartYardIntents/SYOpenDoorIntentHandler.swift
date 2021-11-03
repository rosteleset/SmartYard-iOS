//
//  SYOpenDoorIntentHandler.swift
//  SmartYardIntents
//
//  Created by Александр Васильев on 26.09.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import SmartYardSharedDataFramework
import Intents
import SwifterSwift

@available(iOSApplicationExtension 14.0, *)
class SYOpenDoorIntentHandler: NSObject, SYOpenDoorIntentHandling {
    
    func resolveAddress(
        for intent: SYOpenDoorIntent,
        with completion: @escaping (HouseAddressResolutionResult) -> Void
    ) {
        guard let address = intent.address else {
            completion(.needsValue())
            return
        }
        
        let matchedItems = addresses(of: intent.doorType)
            .filter { $0.identifier == address.identifier }
            
        print("resolveAddress: \(address)")
        print("matchedAdresses: \(matchedItems)")
        
        switch matchedItems.count {
        case 0:
            completion(.unsupported())
        case 1:
            completion(.success(with: address))
        default:
            completion(.disambiguation(with: matchedItems))
        }
    }
    
    func resolveDoor(for intent: SYOpenDoorIntent, with completion: @escaping (DoorResolutionResult) -> Void) {
        
        guard let door = intent.door else {
            completion(.needsValue())
            return
        }
        
        let matchedItems = doors(for: intent.address?.identifier, of: intent.doorType)
            .filter {
                $0.domophoneId == intent.door?.domophoneId &&
                $0.doorId == intent.door?.doorId
            }
        
        print("resolveDoor: \(door) for \(intent.address?.displayString ?? "")")
        print("matchedDoors: \(matchedItems)")
        
        switch matchedItems.count {
        case 0:
            completion(.unsupported())
        case 1:
            completion(.success(with: door))
        default:
            completion(.disambiguation(with: matchedItems))
        }
    }
    
    func provideAddressOptionsCollection(
        for intent: SYOpenDoorIntent,
        with completion: @escaping (INObjectCollection<HouseAddress>?, Error?) -> Void
    ) {
        print("provideAddress - ")
        
        let allItems = addresses(of: intent.doorType)
        
        print(allItems)
        completion(INObjectCollection(items: allItems), nil)
    }
    
    func provideDoorOptionsCollection(
        for intent: SYOpenDoorIntent,
        with completion: @escaping (INObjectCollection<Door>?, Error?) -> Void
    ) {
        print("provideDoor for \(intent.address?.displayString ?? "<неизвестно>")")
        
        let allItems: [Door] = doors(for: intent.address?.displayString, of: intent.doorType)
        
        print(allItems)
        
        if allItems.isEmpty {
            completion(nil, nil)
        } else {
            completion(INObjectCollection(items: allItems), nil)
        }
    }
    
    var objects: [SmartYardSharedObject] {
        let sharedData = SmartYardSharedDataUtilities.loadSharedData()
        return sharedData?.sharedObjects ?? []
    }
    
    func objects(of type: DoorType) -> [SmartYardSharedObject] {
        var allAddresses = objects
            
        switch type {
        case .entrance:
            allAddresses = allAddresses.filter { $0.logoImageName == "HouseIcon" }
        case .gate:
            allAddresses = allAddresses.filter { $0.logoImageName == "BarrierIcon" || $0.logoImageName == "GateIcon" }
        case .wicket:
            allAddresses = allAddresses.filter { $0.logoImageName == "WicketIcon" }
        default:
            ()
        }
        
        return allAddresses
    }
    func addresses(of type: DoorType) -> [HouseAddress] {
        objects(of: type)
            .map { $0.objectAddress }
            .withoutDuplicates()
            .map { adddress -> HouseAddress in
                HouseAddress(identifier: adddress, display: adddress)
            }
    }
    
    func doors(for address: String?, of type: DoorType) -> [Door] {
        guard address != nil else {
            return []
        }
        
        return objects(of: type)
            .filter { $0.objectAddress == address }
            .map { object -> Door in
                let door = Door(identifier: object.objectName, display: object.objectName)
                door.domophoneId = NSNumber(value: Int(object.domophoneId) ?? 0)
                door.doorId = NSNumber(value: object.doorId)
                return door
            }
    }
    
    func confirm(intent: SYOpenDoorIntent, completion: @escaping (SYOpenDoorIntentResponse) -> Void) {
        completion(SYOpenDoorIntentResponse(code: .success, userActivity: nil))
    }
    
    func handle(intent: SYOpenDoorIntent, completion: @escaping (SYOpenDoorIntentResponse) -> Void) {
        guard
            let uObject = SmartYardSharedDataUtilities.loadSharedData(),
            let doorIdNS = intent.door?.doorId,
            let domophoneIdNS = intent.door?.domophoneId
        else {
            completion(SYOpenDoorIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        SmartYardSharedDataUtilities.sendOpenDoorRequest(
            accessToken: uObject.accessToken,
            backendURL: uObject.backendURL ?? Constants.defaultBackendURL ,
            doorId: Int(truncating: doorIdNS),
            domophoneId: String(Int(truncating: domophoneIdNS))
        )
        completion(SYOpenDoorIntentResponse(code: .success, userActivity: nil))
    }
    
}
