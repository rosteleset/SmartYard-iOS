//
//  ParanoidPushPayload.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation

struct ParanoidPushPayload: Equatable {
    let title: String
    let body: String
    let date: String
    let hash: String?
    let imageUrl: String?

    init?(
        userInfo: [AnyHashable: Any],
        notificationTitle: String?,
        notificationBody: String?,
        providerBaseURL: String,
        serverTimeZone: String,
        now: Date = Date()
    ) {
        guard Self.isParanoidAction(userInfo) else { return nil }

        title = Self.stringValue(for: "title", in: userInfo)
            ?? Self.stringValue(for: "gcm.notification.title", in: userInfo)
            ?? Self.alertValue(for: "title", in: userInfo)
            ?? notificationTitle
            ?? ""

        body = Self.stringValue(for: "body", in: userInfo)
            ?? Self.stringValue(for: "gcm.notification.body", in: userInfo)
            ?? Self.alertValue(for: "body", in: userInfo)
            ?? notificationBody
            ?? ""

        hash = Self.stringValue(for: "hash", in: userInfo)
        imageUrl = hash.map { Self.imageURL(providerBaseURL: providerBaseURL, hash: $0) }
        date = Self.formattedDate(
            timestamp: userInfo["timestamp"],
            serverTimeZone: serverTimeZone,
            now: now
        )
    }

    static func isParanoidAction(_ userInfo: [AnyHashable: Any]) -> Bool {
        return stringValue(for: "action", in: userInfo) == "paranoid"
    }

    static func keyValuePayload(
        userInfo: [AnyHashable: Any],
        providerBaseURL: String,
        serverTimeZone: String,
        now: Date = Date()
    ) -> ParanoidPushPayload? {
        return ParanoidPushPayload(
            userInfo: userInfo,
            notificationTitle: nil,
            notificationBody: nil,
            providerBaseURL: providerBaseURL,
            serverTimeZone: serverTimeZone,
            now: now
        )
    }

    static func imageURL(providerBaseURL: String, hash: String) -> String {
        let separator = providerBaseURL.hasSuffix("/") ? "" : "/"
        return providerBaseURL + separator + "call/camshot/" + hash
    }

    static func formattedDate(
        timestamp: Any?,
        serverTimeZone: String,
        now: Date = Date()
    ) -> String {
        let date: Date = {
            guard let seconds = unixSeconds(from: timestamp) else { return now }
            return Date(timeIntervalSince1970: TimeInterval(seconds))
        }()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU_POSIX")
        formatter.timeZone = TimeZone(identifier: serverTimeZone) ?? TimeZone.current
        formatter.dateFormat = "dd.MM.yyyy, HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func unixSeconds(from timestamp: Any?) -> Int64? {
        switch timestamp {
        case let value as Int:
            return Int64(value)
        case let value as Int64:
            return value
        case let value as Double:
            return Int64(value)
        case let value as String:
            return Int64(value)
        default:
            return nil
        }
    }

    private static func stringValue(for key: String, in userInfo: [AnyHashable: Any]) -> String? {
        return userInfo[key] as? String
    }

    private static func alertValue(for key: String, in userInfo: [AnyHashable: Any]) -> String? {
        guard let aps = userInfo["aps"] as? [AnyHashable: Any] else { return nil }

        if let alert = aps["alert"] as? [AnyHashable: Any] {
            return alert[key] as? String
        }

        if key == "body",
           let alert = aps["alert"] as? String {
            return alert
        }

        return nil
    }
}
