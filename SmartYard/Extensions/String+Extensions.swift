//
//  UIString+Extensions.swift
//  SmartYard
//
//  Created by Mad Brains on 18.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import CommonCrypto
import SHSPhoneComponent

extension String {
    
    private mutating func formatAsPhoneNumber() -> String {
        guard count == AccessService.shared.phoneLengthWithPrefix else {
            return self
        }
        let formatter = SHSPhoneNumberFormatter()
        formatter.setDefaultOutputPattern("+" + AccessService.shared.phonePrefix + " " + AccessService.shared.phonePattern)
        
        return formatter.values(for: self)["text"] as? String ?? self
    }
    
    // Сырой номер без префикса (9271234567), 10 цифр
    var rawPhoneNumberFromFullNumber: String? {
        let contactNumber = self
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "") // тире
            .replacingOccurrences(of: "‑", with: "") // дефис
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        guard contactNumber.count >= AccessService.shared.phoneLengthWithoutPrefix else {
            return nil
        }
        
        return String(contactNumber.suffix(AccessService.shared.phoneLengthWithoutPrefix))
    }
    
    // Форматированный номер ( +7 (927) 123-45-67 )
    var formattedNumberFromRawNumber: String? {
        guard count == AccessService.shared.phoneLengthWithoutPrefix else {
            return nil
        }
        
        var mutableString = "+" + AccessService.shared.phonePrefix + self
        
        return mutableString.formatAsPhoneNumber()
    }
    
}

extension String {
    
    var md5: String {
        let data = Data(self.utf8)
        
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
}
