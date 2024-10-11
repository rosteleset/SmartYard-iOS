//
//  CalendarDateRange.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 20.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct CalendarDateRange {
    
    let period: Int
    let component: Calendar.Component
    let to: Date
    let calendar = Calendar.novokuznetskCalendar
    
    var startDate: Date {
        return calendar.startOfDay(for: calendar.date(byAdding: component, value: -period, to: to)!)
    }
    
    var endDate: Date {
        return calendar.date(byAdding: .hour, value: 24, to: calendar.startOfDay(for: to))!
    }
    
    func intersects(start: Date, end: Date) -> Bool {
        if  (startDate < end) && (endDate > start) {
            return true
        }
        return false
    }
}
