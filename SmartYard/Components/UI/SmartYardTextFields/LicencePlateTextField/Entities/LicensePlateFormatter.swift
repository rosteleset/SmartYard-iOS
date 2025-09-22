//
//  LicensePlateFormatter.swift
//  SmartYard
//
//  Created by Александр Попов on 16.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

enum LicencePlateFormatter {
    
    static func format(text: String, format: LicensePlateFormat) -> String {
        let chars = Array(text.uppercased())
        
        switch format {
        case .russia:
            return formatRussia(chars)
        case .belarus:
            return formatBelarus(chars)
        case .kazakhstan:
            return formatKazakhstan(chars)
        case .uzbekistan:
            return formatUzbekistan(chars)
        case .bulgaria:
            return formatBulgaria(chars)
        }
    }

    static func unformat(text: String) -> String {
        return text.replacingOccurrences(of: " ", with: "")
                   .replacingOccurrences(of: "-", with: "")
    }

    // MARK: Россия: А 123 BC 77
    private static func formatRussia(_ chars: [Character]) -> String {
        var result = ""
        for (index, char) in chars.enumerated() {
            if index == 1 || index == 4 || index == 6 { result.append(" ") }
            result.append(char)
        }
        return result
    }

    // MARK: Беларусь: 1234 АВ-7
    private static func formatBelarus(_ chars: [Character]) -> String {
        var result = ""
        for (index, char) in chars.enumerated() {
            if index == 4 { result.append(" ") }
            if index == 7 { result.append("-") }
            result.append(char)
        }
        return result
    }

    // MARK: Казахстан: 123 ABC 01
    private static func formatKazakhstan(_ chars: [Character]) -> String {
        var result = ""
        for (index, char) in chars.enumerated() {
            if index == 3 || index == 6 { result.append(" ") }
            result.append(char)
        }
        return result
    }

    // MARK: Узбекистан: 10 A 456 AB
    private static func formatUzbekistan(_ chars: [Character]) -> String {
        var result = ""
        for (index, char) in chars.enumerated() {
            if index == 2 || index == 3 || index == 6 { result.append(" ") }
            result.append(char)
        }
        return result
    }

    // MARK: Болгария: CA 1234 AB
    private static func formatBulgaria(_ chars: [Character]) -> String {
        var result = ""
        for (index, char) in chars.enumerated() {
            if index == 2 || index == 6 { result.append(" ") }
            result.append(char)
        }
        return result
    }
}
