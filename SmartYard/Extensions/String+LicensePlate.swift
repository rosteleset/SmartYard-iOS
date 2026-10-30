// Created by Александр Попов. Copyright © 2026 Sesameware.

import Foundation

extension String {
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

}
