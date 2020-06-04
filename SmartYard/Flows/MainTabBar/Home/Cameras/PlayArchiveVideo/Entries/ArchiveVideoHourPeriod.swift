//
//  ArchiveVideoHourPeriod.swift
//  SmartYard
//
//  Created by admin on 03.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct ArchiveVideoHourPeriod: Equatable {
    
    let baseDate: Date
    let startHours: Int
    let endHours: Int
    
    var title: String {
        return String(format: "%02d", startHours) + ".00 - " + String(format: "%02d", endHours) + ".00"
    }
    
    var videoUrlComponents: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        
        guard let date = Calendar.current.date(from: components) else {
            return ""
        }
        
        let startDate = date.adding(.hour, value: startHours)
        let endDate = date.adding(.hour, value: endHours)
        
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        return "index-\(startTimestamp)-\(duration).m3u8"
    }
    
}
