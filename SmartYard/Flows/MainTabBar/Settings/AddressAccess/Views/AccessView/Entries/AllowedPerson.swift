//
//  AllowedPerson.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

struct AllowedPerson: Hashable {
    
    let displayedName: String?
    
    // 10 цифр без префикса (9271234567)
    let rawNumber: String
    
    var logoImage: UIImage?
    
    var formattedNumber: String {
        guard rawNumber.count == Constants.phoneLengthWithoutPrefix else {
            fatalError("Неправильный формат номера")
        }
        
        var withSeven = "+7" + rawNumber
        
        return withSeven.formatAsPhoneNumber()
    }
    
    var apiNumber: String {
        guard rawNumber.count == Constants.phoneLengthWithoutPrefix else {
            fatalError("Неправильный формат номера")
        }
        
        return "8" + rawNumber
    }
    
}
