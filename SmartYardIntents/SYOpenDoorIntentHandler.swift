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
    
    func resolveAddress(for intent: SYOpenDoorIntent, with completion: @escaping (HouseAddressResolutionResult) -> Void) {
        guard let address = intent.address else {
            completion(.needsValue())
            return
        }
        
        let matchedItems = addresses()
            .filter { $0 == address.displayString }
            .map {HouseAddress(identifier: $0, display: $0)}
        
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
    
    func provideAddressOptionsCollection(for intent: SYOpenDoorIntent, with completion: @escaping (INObjectCollection<HouseAddress>?, Error?) -> Void) {
        print("provideAddress - ")
        
        let allItems = addresses().map { HouseAddress(identifier: $0, display: $0) }
        
        print(allItems)
        completion(INObjectCollection(items: allItems), nil)
    }
    
    
    var objects: [SmartYardSharedObject] {
        let sharedData = SmartYardSharedDataUtilities.loadSharedData()
        return sharedData.sharedObjects
    }
    
    func addresses() -> [String] {
        objects
            .filter { $0.logoImageName == "HouseIcon"}
            .map { $0.objectAddress }
            .withoutDuplicates()
    }
    
    func doors(for address: String?) -> [String] {
        guard address != nil else {
            return []
        }
        
        return objects
            .filter { $0.logoImageName == "HouseIcon" && $0.objectAddress == address }
            .map { $0.objectName }
            .withoutDuplicates()
    }
    
    func resolveDoor(for intent: SYOpenDoorIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        
        guard let door = intent.door else {
            completion(INStringResolutionResult.needsValue())
            return
        }
        
        let matchedItems = doors(for: intent.address?.displayString)
            .filter { $0 == intent.door }
        
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
    
    func provideDoorOptionsCollection(for intent: SYOpenDoorIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
        print("provideDoor for \(intent.address?.displayString ?? "<неизвестно>")")
        
        let allItems = doors(for: intent.address?.displayString).map { NSString(string: $0) }
        
        print(allItems)
        
        if allItems.isEmpty {
            //     completion(nil, INIntentError.init(_nsError: NSError(domain: "com.Domain.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error Message"])))
            completion(nil, nil)
        } else {
            completion(INObjectCollection(items: allItems), nil)
        }
    }
    
    func defaultDoor(for intent: SYOpenDoorIntent) -> String? {
        return("test")
    }
    
    func confirm(intent: SYOpenDoorIntent, completion: @escaping (SYOpenDoorIntentResponse) -> Void) {
        completion(SYOpenDoorIntentResponse.init(code: .success, userActivity: nil))
    }
    
}
