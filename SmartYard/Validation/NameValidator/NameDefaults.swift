//
//  NameDefaults.swift
//  SmartYard
//
//  Created by Александр Попов on 22.09.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

enum NameDefaults {
    static let first = NamePartConfig(
        min: 1,
        max: 60,
        defaultPattern: #"^[A-Za-zА-Яа-яЁё\-\s'’]+$"#,
        allowEmpty: false,
        errorMessageKey: "Please enter a valid first name"
    )

    static let last = NamePartConfig(
        min: 1,
        max: 60,
        defaultPattern: #"^[A-Za-zА-Яа-яЁё\-\s'’]+$"#,
        allowEmpty: false,
        errorMessageKey: "Please enter a valid last name"
    )

    static let patronymic = NamePartConfig(
        min: 1,
        max: 60,
        defaultPattern: #"^[A-Za-zА-Яа-яЁё\-\s]+$"#,
        allowEmpty: true,
        errorMessageKey: "Please enter a valid patronymic"
    )
}
