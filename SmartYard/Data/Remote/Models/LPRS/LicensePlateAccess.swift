//
//  LicensePlateAccess.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation

enum LicensePlateAPIVersion: Int {
    case legacy = 1
    case timed = 2

    init(serverValue: String?) {
        self = serverValue == "2" ? .timed : .legacy
    }
}

struct LicensePlateValidity: Equatable {
    let validFrom: Date?
    let validTo: Date?

    static let unlimited = LicensePlateValidity(validFrom: nil, validTo: nil)

    var isUnlimited: Bool { validFrom == nil && validTo == nil }
    var isValid: Bool {
        guard let validFrom, let validTo else { return true }
        return validTo >= validFrom
    }
    var lasts24Hours: Bool {
        guard let validFrom, let validTo else { return false }
        return abs(validTo.timeIntervalSince(validFrom) - 24 * 60 * 60) < 1
    }

    static func day(startingAt start: Date) -> LicensePlateValidity {
        LicensePlateValidity(validFrom: start, validTo: start.addingTimeInterval(24 * 60 * 60))
    }

    static func apiString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    static func date(from value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

struct APILicensePlate: Decodable {
    let plateNumber: String
    let countryCode: String
    let validity: LicensePlateValidity
    let watcherId: Int?

    private enum CodingKeys: String, CodingKey {
        case plateNumber, countryCode, validFrom, validTo, watcherId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        plateNumber = try container.decode(String.self, forKey: .plateNumber)
        let country = try container.decodeIfPresent(String.self, forKey: .countryCode)
        countryCode = country.flatMap { $0.isEmpty ? nil : $0.lowercased() } ?? "ru"
        validity = LicensePlateValidity(
            validFrom: try Self.decodeDate(container, key: .validFrom),
            validTo: try Self.decodeDate(container, key: .validTo)
        )
        if let value = try? container.decode(Int.self, forKey: .watcherId) {
            watcherId = value > 0 ? value : nil
        } else if let value = try? container.decode(String.self, forKey: .watcherId), let id = Int(value) {
            watcherId = id > 0 ? id : nil
        } else {
            watcherId = nil
        }
    }

    private static func decodeDate(
        _ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys
    ) throws -> Date? {
        guard let value = try container.decodeIfPresent(String.self, forKey: key), !value.isEmpty else {
            return nil
        }
        guard let date = LicensePlateValidity.date(from: value) else {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: container, debugDescription: "Invalid license plate validity date"
            )
        }
        return date
    }
}

struct APILicensePlateFormat: Decodable, Equatable {
    let countryCode: String
    let regex: String

    func matches(_ number: String) -> Bool {
        guard let expression = try? NSRegularExpression(pattern: regex) else { return false }
        let range = NSRange(number.startIndex..., in: number)
        return expression.firstMatch(in: number, range: range)?.range == range
    }
}
