//
//  UIString+Extensions.swift
//  SmartYard
//
//  Created by Mad Brains on 18.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

extension String {
    
    mutating func formatAsPhoneNumber() -> String {
        guard count == Constants.phoneLengthWithPrefix else {
            return self
        }
        
        insert("(", at: index(startIndex, offsetBy: 2))
        insert(")", at: index(startIndex, offsetBy: 6))
        insert("-", at: index(startIndex, offsetBy: 10))
        insert("-", at: index(startIndex, offsetBy: 13))
        
        return self
    }
    
}
