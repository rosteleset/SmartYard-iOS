//
//  ContractFaceObject.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

struct ContractFaceObject: Equatable, Hashable {
    let number: Int
    let houseId: String
    let contractName: String
    let address: String
    let cityName: String
    let balance: Double
    let services: [SettingsServiceType: Bool]
    let clientId: String
    let limitStatus: Bool
    let limitAvailable: Bool
    let limitDays: Int?
    let parentEnable: Bool
    var parentStatus: Bool?
    var details: ContractDetailObject
    var position: PositionContractType = .face
    
    public var hashValue: Int {
        return number.hashValue ^ houseId.hashValue ^ contractName.hashValue
    }
}
