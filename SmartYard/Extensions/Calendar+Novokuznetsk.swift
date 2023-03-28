//
//  Calendar+Moscow.swift
//  SmartYard
//
//  Created by admin on 09.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

extension Calendar {
    
    static let novokuznetskCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        
        calendar.timeZone = TimeZone(identifier: "Asia/Novokuznetsk") ?? TimeZone.current
        calendar.locale = .init(identifier: "RU")
        
        return calendar
    }()
    
}
