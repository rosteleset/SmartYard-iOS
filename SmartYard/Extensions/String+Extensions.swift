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
    
    /// Стандартизированный номер в латинице, например `M565XV68`
    var standardizedCarNumber: String {
        let translitMap: [Character: Character] = [
            "А": "A", "В": "B", "Е": "E", "К": "K",
            "М": "M", "Н": "H", "О": "O", "Р": "P",
            "С": "C", "Т": "T", "У": "Y", "Х": "X"
        ]
        
        let cleaned = self
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let transliterated = cleaned.map { char in
            translitMap[char] ?? char
        }

        let result = String(transliterated)
        
        let pattern = #"^[A-Z]{1}\d{3}[A-Z]{2}\d{2,3}$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: result.utf16.count)

        if regex?.firstMatch(in: result, options: [], range: range) != nil {
            return result
        } else {
            return self
        }
    }
    
    /// Читаемый формат: `М 565 ХВ 68`
    var displayCarNumber: String {
        let reverseTranslitMap: [Character: Character] = [
            "A": "А", "B": "В", "E": "Е", "K": "К",
            "M": "М", "H": "Н", "O": "О", "P": "Р",
            "C": "С", "T": "Т", "Y": "У", "X": "Х"
        ]
        
        let clean = self.replacingOccurrences(of: " ", with: "").uppercased()
        guard clean.count >= 8 else { return self }

        let chars = Array(clean)
        let first = reverseTranslitMap[chars[0]] ?? chars[0]
        let digits = String(chars[1...3])
        let middleLetters = chars[4...5].map { reverseTranslitMap[$0] ?? $0 }
        let region = String(chars.suffix(from: 6))

        return "\(first) \(digits) \(String(middleLetters)) \(region)"
    }
    
    /// Сырой номер без префикса, 10 цифр: `(9271234567)`
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
    
    /// Форматированный номер: `+7 (927) 123-45-67`
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

extension String {
    
    func withoutPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
}
