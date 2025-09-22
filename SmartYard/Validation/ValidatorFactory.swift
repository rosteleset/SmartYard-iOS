//
//  ValidatorFactory.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

enum ValidatorFactory {

    // MARK: Name Validator

    static func makeFirst(from p: NameValidationPattern?) -> NamePartValidatior {
        NamePartValidatior(config: NameDefaults.first, serverRegex: p?.validationNamePattern)
    }

    static func makeLast(from p: NameValidationPattern?) -> NamePartValidatior {
        NamePartValidatior(config: NameDefaults.last, serverRegex: p?.validationLastPattern)
    }

    static func makePatronymic(from p: NameValidationPattern?) -> NamePartValidatior {
        NamePartValidatior(config: NameDefaults.patronymic, serverRegex: p?.validationPatronymicPattern)
    }

}
