//
//  CameraExtendedObject.swift
//  SmartYard
//
//  Created by devcentra on 24.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import CoreLocation

enum CameraExtendedType: String {
    case intercom
    case home
    case city
}

struct DoorExtendedObject: Equatable {
    let domophoneId: String
    let doorId: Int
    let entrance: String
    let type: String
    let name: String
    let blocked: String
    let dst: String
}

struct CameraExtendedObject: Equatable {
    let id: Int
    let position: CLLocationCoordinate2D
    let cameraNumber: Int
    let name: String
    let video: String
    let token: String
    let doors: [DoorExtendedObject]
    let flatIds: [String?]
    let type: CameraExtendedType?
    var status: Bool?
}
