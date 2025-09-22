//
//  NSRegularExpression+Extensions.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    /// Удобный конструктор для безопасного создания NSRegularExpression.
    /// - Parameter pattern: строка с regex (может быть nil или пустая).
    /// - Returns: скомпилированный NSRegularExpression или nil, если строка некорректна.
    static func make(_ pattern: String?) -> NSRegularExpression? {
        guard let p = pattern, !p.isEmpty else {
            return nil 
        }
        return try? NSRegularExpression(pattern: p)
    }
}
