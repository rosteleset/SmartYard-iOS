//
//  AllowedCar.swift
//  SmartYard
//
//  Created by Александр Попов on 11.06.2025.
//  Copyright © 2025 Sesameware. All rights reserved.
//

import Foundation

struct AllowedCar: Hashable {
    let rawNumber: String
    let countryCode: String
    let validFrom: Date?
    let validTo: Date?
    let watcherId: Int?

    init(
        rawNumber: String,
        countryCode: String = "ru",
        validFrom: Date? = nil,
        validTo: Date? = nil,
        watcherId: Int? = nil
    ) {
        self.rawNumber = rawNumber
        self.countryCode = countryCode.lowercased()
        self.validFrom = validFrom
        self.validTo = validTo
        self.watcherId = watcherId
    }

    var displayedNumber: String { countryCode == "ru" ? rawNumber.displayCarNumber : rawNumber }
    var apiNumber: String { rawNumber.standardizedCarNumber }
    var identity: String { countryCode + ":" + apiNumber }
    var validity: LicensePlateValidity { .init(validFrom: validFrom, validTo: validTo) }
    var isExpired: Bool { validTo.map { $0 <= Date() } ?? false }

    func withWatcher(_ watcherId: Int?) -> AllowedCar {
        AllowedCar(
            rawNumber: rawNumber,
            countryCode: countryCode,
            validFrom: validFrom,
            validTo: validTo,
            watcherId: watcherId
        )
    }

    func validityDescription(timeZone: TimeZone, now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = timeZone
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        if let validFrom, validFrom > now {
            return String(format: L10n.Settings.VehiclePass.validFrom, formatter.string(from: validFrom))
        }
        if let validTo {
            return String(format: L10n.Settings.VehiclePass.validUntil, formatter.string(from: validTo))
        }
        return L10n.Settings.AddressAccess.GateDetails.unlimited
    }
}
