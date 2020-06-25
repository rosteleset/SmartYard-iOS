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
    
    var videoUrlComponents: String? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        let currentOffsetFromGMT = Calendar.current.timeZone.secondsFromGMT() / 3600
        let moscowOffsetFromGMT = 3
        let diff = currentOffsetFromGMT - moscowOffsetFromGMT
        
        let startDate = date.adding(.hour, value: startHours + diff)
        let endDate = date.adding(.hour, value: endHours + diff)
        
        let startTimestamp = startDate.unixTimestamp.int
        let duration = endDate.timeIntervalSince(startDate).int
        
        return "/index-\(startTimestamp)-\(duration).m3u8"
    }
    
    var videoThumbnailComponents: String? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        let moscowOffsetFromGMT = 3
        
        let startDate = date.adding(.hour, value: startHours - moscowOffsetFromGMT)
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy/MM/dd/HH/mm/ss"
        
        return "/\(dateFormatter.string(from: startDate))-preview.mp4"
    }
    
    func recPrepareComponents(start: Float64, end: Float64) -> (from: String, to: String)? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        let startDate = date
            .adding(.hour, value: startHours)
            .adding(.second, value: start.floor.int)
        
        let endDate = date
            .adding(.hour, value: startHours)
            .adding(.second, value: end.ceil.int)
        
        return (from: startDate.apiString, to: endDate.apiString)
    }
    
}
