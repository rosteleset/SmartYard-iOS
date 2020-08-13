//
//  Calendar+Moscow.swift
//  SmartYard
//
//  Created by admin on 09.07.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

extension Calendar {
    
    static let moscowCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow") ?? TimeZone.current
        calendar.locale = .init(identifier: "RU")
        
        return calendar
    }()
    
}
