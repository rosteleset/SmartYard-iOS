//
//  AllowedCar.swift
//  SmartYard
//
//  Created by Александр Попов on 11.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation

struct AllowedCar: Hashable {
    
    let rawNumber: String
    
    var displayedNumber: String {
        rawNumber.displayCarNumber
    }
    
    var apiNumber: String {
        rawNumber.standardizedCarNumber
    }
    
}
