//
//  MapCamera.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import CoreLocation

struct DoorObject: Equatable {
    let domophoneId: String
    let doorId: Int
    let entrance: String
    let type: String
    let name: String
    let blocked: String
    let dst: String
}

struct CameraObject: Equatable {
    
    let id: Int
    let position: CLLocationCoordinate2D
    let cameraNumber: Int
    let name: String
    let video: String
    let token: String
    let doors: [DoorObject]
    
}
