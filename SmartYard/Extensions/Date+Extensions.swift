//
//  Date+Extensions.swift
//  SmartYard
//
//  Created by Mad Brains on 21.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

extension Date {
    
    var dateHourAfter: Date {
        return Calendar.current.date(byAdding: .minute, value: 60, to: self) ?? Date()
    }
    
    var apiString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
    
}
