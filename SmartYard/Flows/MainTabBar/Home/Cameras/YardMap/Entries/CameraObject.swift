//
//  MapCamera.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import CoreLocation

struct CameraObject: Equatable {
    
    let id: Int
    let position: CLLocationCoordinate2D
    let cameraNumber: Int
    let name: String
    let video: String
    let token: String
    
}
