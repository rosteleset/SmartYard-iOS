//
//  NamePartValidatior.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation

struct NamePartValidator: TextValidation {
    private let rules: [ValidationRule]
    private let allowEmpty: Bool
    let errorMessage: String?

    init(config: NamePartConfig, serverRegex: String?) {
        self.allowEmpty = config.allowEmpty
        self.errorMessage = NSLocalizedString(config.errorMessageKey, comment: "")

        var rules: [ValidationRule] = [
            .minLength(config.min),
            .maxLength(config.max)
        ]

        let regex = NSRegularExpression.make(serverRegex) ?? NSRegularExpression.make(config.defaultPattern)!
        rules.append(.regex(regex))

        self.rules = rules
    }

    func validate(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if allowEmpty, trimmed.isEmpty { return true }
        guard !trimmed.isEmpty else { return false }

        return rules.allSatisfy { $0.check(trimmed) }
    }
}
