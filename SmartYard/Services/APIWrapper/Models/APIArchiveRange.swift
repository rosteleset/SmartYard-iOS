//
//  APIArchiveRange.swift
//  SmartYard
//
//  Created by admin on 08.07.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct APIArchiveRange: Decodable {
    
    let duration: Int
    let from: Int
    
    var startDate: Date {
        return Date(timeIntervalSince1970: from.double)
    }
    
    var endDate: Date {
        return startDate.addingTimeInterval(duration.double)
    }
    
    func intersects(start: Date, end: Date) -> Bool {
        if  (startDate < end) && (endDate > start) {
            return true
        }
        return false
    }
}
