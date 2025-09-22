//
//  ValidatorFactory.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

enum ValidatorFactory {

    // MARK: Name Validator

    static func makeFirst(from p: NameValidationPattern?) -> NamePartValidator {
        NamePartValidator(config: NameDefaults.first, serverRegex: p?.validationNamePattern)
    }

    static func makeLast(from p: NameValidationPattern?) -> NamePartValidator {
        NamePartValidator(config: NameDefaults.last, serverRegex: p?.validationLastPattern)
    }

    static func makePatronymic(from p: NameValidationPattern?) -> NamePartValidator {
        NamePartValidator(config: NameDefaults.patronymic, serverRegex: p?.validationPatronymicPattern)
    }

}
