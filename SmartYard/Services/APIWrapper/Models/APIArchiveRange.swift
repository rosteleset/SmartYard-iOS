//
//  APIArchiveRange.swift
//  SmartYard
//
//  Created by admin on 08.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIArchiveRange: Decodable {
    
    var duration: Double
    let from: Int
    
    var startDate: Date {
        return Date(timeIntervalSince1970: from.double)
    }
    
    var endDate: Date {
        return startDate.addingTimeInterval(duration)
    }
    
    func intersects(start: Date, end: Date) -> Bool {
        if  (startDate < end) && (endDate > start) {
            return true
        }
        return false
    }
}
