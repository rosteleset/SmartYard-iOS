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
        guard self.count == Constants.phoneLengthWithPrefix else {
            return self
        }
        
        self.insert("-", at: self.index(self.startIndex, offsetBy: 2))
        self.insert("-", at: self.index(self.startIndex, offsetBy: 6))
        self.insert("-", at: self.index(self.startIndex, offsetBy: 10))
        self.insert("-", at: self.index(self.startIndex, offsetBy: 13))
        
        return self
    }
    
}
