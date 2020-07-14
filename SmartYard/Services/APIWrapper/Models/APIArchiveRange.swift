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
    
}

extension APIArchiveRange {
    
    var lowerDateLimitForCalendar: Date? {
        let startOfDay = Calendar.moscowCalendar.startOfDay(for: startDate)
        
        return lowerDateLimitForCalendar(baseDate: startOfDay)
    }
    
    var upperDateLimitForCalendar: Date? {
        let startOfDay = Calendar.moscowCalendar.startOfDay(for: endDate)
        
        return upperDateLimitForCalendar(baseDate: startOfDay)
    }
    
    private func lowerDateLimitForCalendar(baseDate: Date) -> Date? {
        let periods = (0...7).map {
            ArchiveVideoHourPeriod(baseDate: baseDate, startHours: $0 * 3, endHours: $0 * 3 + 3)
        }
        
        let match = periods.first { period in
            let periodStart = period.baseDate.adding(.hour, value: period.startHours)
            let periodEnd = period.baseDate.adding(.hour, value: period.endHours)
            
            return periodStart.isBetween(startDate, endDate, includeBounds: true) &&
                periodEnd.isBetween(startDate, endDate, includeBounds: true)
        }
        
        guard match == nil else {
            return baseDate
        }
        
        let startOfNextDay = baseDate.adding(.day, value: 1)
        
        guard startOfNextDay <= endDate else {
            return nil
        }
        
        return lowerDateLimitForCalendar(baseDate: startOfNextDay)
    }
    
    private func upperDateLimitForCalendar(baseDate: Date) -> Date? {
        let periods = (0...7).map {
            ArchiveVideoHourPeriod(baseDate: baseDate, startHours: $0 * 3, endHours: $0 * 3 + 3)
        }
        
        let match = periods.first { period in
            let periodStart = period.baseDate.adding(.hour, value: period.startHours)
            let periodEnd = period.baseDate.adding(.hour, value: period.endHours)
            
            return periodStart.isBetween(startDate, endDate, includeBounds: true) &&
                periodEnd.isBetween(startDate, endDate, includeBounds: true)
        }
        
        guard match == nil else {
            return baseDate
        }
        
        let startOfPreviousDay = baseDate.adding(.day, value: -1)
        
        guard startOfPreviousDay >= startDate else {
            return nil
        }
        
        return upperDateLimitForCalendar(baseDate: startOfPreviousDay)
    }
    
}
