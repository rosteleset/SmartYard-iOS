//
//  ValidationRule.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation

enum ValidationRule {
    case minLength(Int)
    case maxLength(Int)
    case regex(NSRegularExpression)

    func check(_ text: String) -> Bool {
        switch self {
        case .minLength(let min): return text.count >= min
        case .maxLength(let max): return text.count <= max
        case .regex(let regex):
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            guard let match = regex.firstMatch(in: text, options: [], range: range) else {
                return false
            }

            return match.range == range
        }
    }
}
