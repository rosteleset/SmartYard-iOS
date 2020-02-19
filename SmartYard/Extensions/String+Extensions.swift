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
        
        insert(" ", at: index(startIndex, offsetBy: 2))
        insert("(", at: index(startIndex, offsetBy: 3))
        insert(")", at: index(startIndex, offsetBy: 7))
        insert(" ", at: index(startIndex, offsetBy: 8))
        insert("-", at: index(startIndex, offsetBy: 12))
        insert("-", at: index(startIndex, offsetBy: 15))
        
        return self
    }
    
}
