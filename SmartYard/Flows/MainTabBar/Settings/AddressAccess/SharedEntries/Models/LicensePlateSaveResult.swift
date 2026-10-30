//
//  LicensePlateSaveResult.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation

struct LicensePlateSaveResult {
    var car: AllowedCar
    var cars: [AllowedCar]?
    var removedOriginal = false
    var issues: [Issue] = []

    enum Issue: Equatable {
        case tracking, originalAccess, refresh

        var message: String {
            switch self {
            case .tracking: return L10n.Settings.VehiclePass.trackingFailed
            case .originalAccess: return L10n.Settings.VehiclePass.originalRemovalFailed
            case .refresh: return L10n.Settings.VehiclePass.refreshFailed
            }
        }
    }

    var warning: String? {
        issues.isEmpty ? nil : issues.map(\.message).joined(separator: "\n\n")
    }

    func updating(_ existing: [AllowedCar], original: AllowedCar?) -> [AllowedCar] {
        if let cars { return cars }
        var updated = existing.filter { $0.identity != car.identity }
        if removedOriginal, let original { updated.removeAll { $0.identity == original.identity } }
        updated.append(car)
        return updated
    }
}

enum LicensePlateAccessError: LocalizedError {
    case unsupportedCountryRemoval
    case invalidPeriod

    var errorDescription: String? {
        switch self {
        case .unsupportedCountryRemoval: return L10n.Settings.VehiclePass.countryRemovalUnavailable
        case .invalidPeriod: return L10n.Settings.VehiclePass.periodInvalid
        }
    }
}
