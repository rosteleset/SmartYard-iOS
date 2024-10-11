//
//  IntercomsExtendedObject.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 15.04.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import CoreLocation

struct DoorIntercomObject: Equatable, Hashable {
    let number: Int
    let camId: Int
    let addressNumber: Int
    let name: String
    let video: String
    let token: String
    let domophoneId: String?
    let doorId: Int?
    let type: DomophoneObjectType?
    let hasPlog: Bool
    let address: String
    let houseId: Int
    let flatId: Int?
    let flat: Int?
    let clientId: Int?
    let events: Int
    let blocked: String?
    var doorcode: String?
    var status: Bool?
}

struct IntercomsExtendedObject: Equatable {
    let number: Int
    let houseId: Int
    let address: String?
    let doors: [DoorIntercomObject]
}
