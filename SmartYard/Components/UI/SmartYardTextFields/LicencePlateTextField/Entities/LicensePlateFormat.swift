//
//  Untitled.swift
//  SmartYard
//
//  Created by Александр Попов on 15.07.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

enum LicensePlateFormat {
    case russia       // А123ВС77
    case belarus      // 1234 АВ-7
    case kazakhstan   // 123ABC01
    case uzbekistan   // 01A123AA
    case bulgaria     // CA1234AB
}

extension LicensePlateFormat {
    var countryCode: String {
        switch self {
        case .russia: return "ru"
        case .belarus: return "by"
        case .kazakhstan: return "kz"
        case .uzbekistan: return "uz"
        case .bulgaria: return "bg"
        }
    }
}
