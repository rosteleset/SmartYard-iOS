//
//  Date+Conversion.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

extension Date {
    
    var apiString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.serverCalendar.timeZone
        dateFormatter.locale = Calendar.serverCalendar.locale
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
    var apiShortString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.serverCalendar.timeZone
        dateFormatter.locale = Calendar.serverCalendar.locale
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
}

extension String {
    
    var dateFromAPIString: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Calendar.serverCalendar.timeZone
        dateFormatter.locale = Calendar.serverCalendar.locale
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let result = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let resultShort = dateFormatter.date(from: self)
        
        return (result != nil) ? result : resultShort
    }
    
}

