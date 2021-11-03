//
//  CityCameraObject.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import CoreLocation

struct CityCameraObject: Equatable {
    
    let id: Int
    let position: CLLocationCoordinate2D
    let cameraNumber: Int
    let name: String
    let video: String
    let token: String
    
}
