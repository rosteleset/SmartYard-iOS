//
//  AllowedPerson.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct AllowedPerson: Hashable {
    
    let roommateType: APIRoommateAccessType
    let displayedName: String?
    
    // 10 цифр без префикса (9271234567)
    let rawNumber: String
    
    var logoImage: UIImage?
    
    var formattedNumber: String {
        guard let fNumber = rawNumber.formattedNumberFromRawNumber else {
            fatalError("Неправильный формат номера")
        }
        
        return fNumber
    }
    
    var apiNumber: String {
        guard rawNumber.count == AccessService.shared.phoneLengthWithoutPrefix else {
            fatalError("Неправильный формат номера")
        }
        
        return AccessService.shared.phonePrefix + rawNumber
    }
    
}
