//
//  LicencePlateValidator.swift
//  SmartYard
//
//  Created by Александр Попов on 09.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

enum LicencePlateValidator {
    
    static func isValidPartialInput(_ input: String, format: LicensePlateFormat) -> Bool {
        switch format {
        case .russia:
            return validateRussia(input)
        case .belarus:
            return validateBelarus(input)
        case .kazakhstan:
            return validateKazakhstan(input)
        case .uzbekistan:
            return validateUzbekistan(input)
        case .bulgaria:
            return validateBulgaria(input)
        }
    }
    
    // MARK: - Россия: А123ВС77 или А123ВС197
    private static func validateRussia(_ input: String) -> Bool {
        let chars = Array(input.uppercased())
        
        for (index, char) in chars.enumerated() {
            switch index {
            case 0, 4, 5:
                if !isCyrillicLetter(char) { return false }
            case 1, 2, 3, 6, 7:
                if !char.isNumber { return false }
            case 8:
                if chars.count == 9 && !char.isNumber { return false }
            default:
                return false
            }
        }
        return true
    }
    
    // MARK: - Беларусь: 1234 АВ-7 (цифры, пробел, буквы, дефис, цифра)
    // swiftlint:disable cyclomatic_complexity
    private static func validateBelarus(_ input: String) -> Bool {
        let chars = Array(input.uppercased())
        
        for (index, char) in chars.enumerated() {
            switch index {
            case 0...3:
                if !char.isNumber { return false }
            case 4:
                if char != " " { return false }
            case 5, 6:
                if !isCyrillicLetter(char) { return false }
            case 7:
                if char != "-" { return false }
            case 8:
                if !char.isNumber { return false }
            default:
                return false
            }
        }
        return true
    }
    // swiftlint:enable cyclomatic_complexity
    
    // MARK: - Казахстан: 123ABC01
    private static func validateKazakhstan(_ input: String) -> Bool {
        let chars = Array(input.uppercased())
        
        for (index, char) in chars.enumerated() {
            switch index {
            case 0...2:
                if !char.isNumber { return false }
            case 3...5:
                if !isLatinLetter(char) { return false }
            case 6, 7:
                if !char.isNumber { return false }
            default:
                return false
            }
        }
        return true
    }
    
    private static func validateUzbekistan(_ input: String) -> Bool {
        let chars = Array(input.uppercased())
        
        for (index, char) in chars.enumerated() {
            switch index {
            case 0, 1:
                if !char.isNumber { return false } // регион
            case 2:
                if !isLatinLetter(char) { return false }
            case 3...5:
                if !char.isNumber { return false }
            case 6, 7:
                if !isLatinLetter(char) { return false }
            default:
                return false
            }
        }
        return true
    }
    
    private static func validateBulgaria(_ input: String) -> Bool {
        let chars = Array(input.uppercased())
        
        for (index, char) in chars.enumerated() {
            switch index {
            case 0, 1:
                if !isLatinLetter(char) { return false }
            case 2...5:
                if !char.isNumber { return false }
            case 6, 7:
                if !isLatinLetter(char) { return false }
            default:
                return false
            }
        }
        return true
    }

    // MARK: - Поддержка кириллицы и латиницы
    private static func isCyrillicLetter(_ char: Character) -> Bool {
        let allowed = "АВЕКМНОРСТУХ"
        return allowed.contains(char)
    }

    private static func isLatinLetter(_ char: Character) -> Bool {
        return ("A"..."Z").contains(char)
    }
    
    // swiftlint:disable cyclomatic_complexity
    static func allowedCharacters(
        for text: String,
        format: LicensePlateFormat
    ) -> (letters: Bool, digits: Bool) {
        let length = text.count

        switch format {
        case .russia:
            switch length {
            case 0: return (true, false)       // А
            case 1...3: return (false, true)   // 123
            case 4, 5: return (true, false)    // ХВ
            case 6...7: return (false, true)   // 77
            case 8: return (false, true)       // 197
            default: return (false, false)
            }

        case .belarus:
            switch length {
            case 0...3: return (false, true)   // 1234
            case 4: return (false, false)      // пробел, мы вставим сами
            case 5, 6: return (true, false)    // АВ
            case 7: return (false, false)      // дефис
            case 8: return (false, true)       // 7
            default: return (false, false)
            }

        case .kazakhstan:
            switch length {
            case 0...2: return (false, true)   // 123
            case 3...5: return (true, false)   // ABC
            case 6...7: return (false, true)   // 01
            default: return (false, false)
            }

        case .uzbekistan:
            switch length {
            case 0...1: return (false, true)   // регион
            case 2: return (true, false)       // A
            case 3...5: return (false, true)   // 456
            case 6, 7: return (true, false)    // AB
            default: return (false, false)
            }

        case .bulgaria:
            switch length {
            case 0...1: return (true, false)   // CA
            case 2...5: return (false, true)   // 1234
            case 6, 7: return (true, false)    // AB
            default: return (false, false)     
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity

    static func isCompleteInput(_ input: String, format: LicensePlateFormat) -> Bool {
        switch format {
        case .russia:
            return input.count == 8 || input.count == 9 // А123ВС77 или А123ВС197
        case .belarus:
            return input.count == 9 // 1234 АВ-7 → 9 символов
        case .kazakhstan:
            return input.count == 8 // 123ABC01
        case .uzbekistan:
            return input.count == 8 // 10A456AB
        case .bulgaria:
            return input.count == 8 // CA1234AB
        }
    }
}
