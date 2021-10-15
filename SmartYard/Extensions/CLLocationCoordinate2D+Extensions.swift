//
//  CLLocationCoordinate2D+Extensions.swift
//  SmartYard
//
//  Created by Mad Brains on 28.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import MapKit

extension CLLocationCoordinate2D: Equatable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        (fabs(lhs.latitude - rhs.latitude) < .ulpOfOne) && (fabs(lhs.longitude - rhs.longitude) < .ulpOfOne)
    }
    
}
