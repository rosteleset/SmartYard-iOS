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
    
    // Сырой номер без префикса (9271234567), 10 цифр
    var rawPhoneNumberFromFullNumber: String? {
        let contactNumber = self
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        guard contactNumber.count >= Constants.phoneLengthWithoutPrefix else {
            return nil
        }
        
        return String(contactNumber.suffix(Constants.phoneLengthWithoutPrefix))
    }
    
}
