//
//  ValidatorFactory.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

enum ValidatorFactory {

    // MARK: Name Validator

    static func makeFirst(from pattern: NameValidationPattern?) -> NamePartValidator {
        NamePartValidator(config: NameDefaults.first, serverRegex: pattern?.validationNamePattern)
    }

    static func makeLast(from pattern: NameValidationPattern?) -> NamePartValidator {
        NamePartValidator(config: NameDefaults.last, serverRegex: pattern?.validationLastPattern)
    }

    static func makePatronymic(from pattern: NameValidationPattern?) -> NamePartValidator {
        NamePartValidator(config: NameDefaults.patronymic, serverRegex: pattern?.validationPatronymicPattern)
    }

}
