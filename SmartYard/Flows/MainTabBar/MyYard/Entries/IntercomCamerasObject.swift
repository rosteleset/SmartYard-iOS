//
//  IntercomCamerasObject.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 06.05.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import CoreLocation

struct CameraInversObject: Equatable {
    let number: Int
    let camId: Int
    let name: String
    let video: String
    let token: String
    let houseId: Int?
}

struct IntercomCamerasObject: Equatable, Hashable {
    let number: Int
    let name: String
    let domophoneId: String
    let doorId: Int
    let type: DomophoneObjectType?
    let hasPlog: Bool
    let address: String?
    let houseId: Int?
    let flatId: Int?
    let flat: Int?
    let clientId: Int?
    let events: Int?
    let blocked: String?
    let cameras: [CameraInversObject]
    var doorcode: String?
    var status: Bool?
    
    public var hashValue: Int {
        return number.hashValue ^ domophoneId.hashValue ^ doorId.hashValue
    }
}
