//
//  AnalyticsTracking.swift
//  SmartYard
//
//  Created by Александр Попов on 13.05.2026.
//

import FirebaseAnalytics
import Foundation

protocol AnalyticsTracking {
    func logEvent(_ event: AnalyticsEvent)
}

struct AnalyticsEvent {
    let name: String
    let parameters: [String: Any]?
}

final class FirebaseAnalyticsTracker: AnalyticsTracking {

    static let shared = FirebaseAnalyticsTracker()

    private init() {}

    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}

enum AppAnalytics {

    static var tracker: AnalyticsTracking = FirebaseAnalyticsTracker.shared

    static func log(_ event: AnalyticsEvent) {
        tracker.logEvent(event)
    }

    static func logError(
        scenario: String,
        screen: String,
        errorCode: String?,
        safeMessage: String?
    ) {
        tracker.logEvent(
            AppAnalyticsEvent.appError(
                scenario: scenario,
                screen: screen,
                errorCode: errorCode,
                safeMessage: safeMessage
            )
        )
    }
}

extension AnalyticsTracking {

    func logError(
        scenario: String,
        screen: String,
        errorCode: String?,
        safeMessage: String?
    ) {
        logEvent(
            AppAnalyticsEvent.appError(
                scenario: scenario,
                screen: screen,
                errorCode: errorCode,
                safeMessage: safeMessage
            )
        )
    }
}

enum AnalyticsAppMetadata {

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }

    static var environment: String {
        #if DEBUG
        return "debug"
        #else
        return "release"
        #endif
    }
}

enum AnalyticsError {

    static func code(from error: Error?) -> String? {
        guard let error = error else {
            return nil
        }

        let nsError = error as NSError
        let domain = normalized(nsError.domain)
        return "\(domain)_\(nsError.code)".replacingOccurrences(of: "-", with: "minus_")
    }

    static func safeMessage(from error: Error?) -> String? {
        guard let error = error else {
            return nil
        }

        return AnalyticsSanitizer.safeMessage(error.localizedDescription)
    }

    private static func normalized(_ value: String) -> String {
        let lowercased = value.lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        let mappedScalars = lowercased.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }

        return String(mappedScalars)
            .replacingOccurrences(of: "__", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

enum AnalyticsSanitizer {

    static func safeMessage(_ message: String?) -> String? {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines),
            !message.isEmpty else {
            return nil
        }

        let sanitized = [
            #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            #"https?://\S+"#,
            #"\+?\d[\d\s().-]{6,}\d"#,
            #"[A-Za-z0-9_-]{32,}"#
        ].reduce(message) { value, pattern in
            replacingMatches(in: value, pattern: pattern, with: "[redacted]")
        }

        return String(sanitized.prefix(120))
    }

    private static func replacingMatches(
        in value: String,
        pattern: String,
        with replacement: String
    ) -> String {
        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return value
        }

        return expression.stringByReplacingMatches(
            in: value,
            options: [],
            range: NSRange(value.startIndex..., in: value),
            withTemplate: replacement
        )
    }
}

enum AnalyticsValue {

    static let unknown = "unknown"
    static let success = "success"
    static let failed = "failed"
    static let cancelled = "cancelled"

    static func qrType(from code: String?) -> String {
        let lowercased = code?.lowercased() ?? ""

        if lowercased.contains("invite") {
            return "invite"
        }

        if lowercased.contains("payment") || lowercased.contains("pay") {
            return "payment"
        }

        if lowercased.contains("access") || lowercased.contains("qr") {
            return "access"
        }

        return unknown
    }

    static func amountRange(from amount: Int?) -> String? {
        guard let amount = amount else {
            return nil
        }

        switch amount {
        case ..<0:
            return nil
        case 0..<500:
            return "0_500"
        case 500..<1_000:
            return "500_1000"
        case 1_000..<3_000:
            return "1000_3000"
        default:
            return "3000_plus"
        }
    }

    static func amountRange(from amount: Double?) -> String? {
        guard let amount = amount else {
            return nil
        }

        return amountRange(from: Int(amount))
    }

    static func amountRange(from amount: NSDecimalNumber?) -> String? {
        guard let amount = amount, amount != NSDecimalNumber.notANumber else {
            return nil
        }

        return amountRange(from: amount.doubleValue)
    }

    static func bool(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}
