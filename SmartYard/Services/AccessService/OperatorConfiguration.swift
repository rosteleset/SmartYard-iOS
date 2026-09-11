//
//  OperatorConfiguration.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 Sesameware. All rights reserved.
//

import Foundation

final class OperatorConfiguration {
    struct Provider: Equatable {
        let id: String
        let name: String
    }

    struct DefaultValues {
        let backendURL: String
        let phonePrefix: String
        let phonePattern: String
        let timeZone: String
        let cctvView: String
        let entrancesView: String
        let activeTab: String
    }

    private enum Key {
        static let backendURL = "backendURL"
        static let providerId = "providerId"
        static let providerName = "providerNameKey"
        static let showPayments = "showPayments"
        static let paymentsURL = "paymentsUrl"
        static let showChat = "showChat"
        static let chatURL = "chatUrl"
        static let supportPhone = "supportPhoneKey"
        static let chatId = "chatId"
        static let chatDomain = "chatDomain"
        static let chatToken = "chatToken"
        static let showCityCams = "showCityCams"
        static let phonePrefix = "phonePrefixKey"
        static let phonePattern = "phonePatternKey"
        static let guestAccessMode = "guestAccessKey"
        static let timeZone = "timeZoneKey"
        static let cctvView = "cctvViewKey"
        static let entrancesView = "entrancesViewKey"
        static let activeTab = "activeTabKey"
        static let issuesVersion = "issuesVersionKey"
        static let nameValidationPattern = "nameValidationPatternKey"
        static let deliveryTabsConfig = "deliveryTabsConfigKey"
        static let eventsTrackingEnabled = "eventsTrackingEnabledKey"
        static let stunURL = "stunUrlKey"
        static let showStories = "showStoriesKey"
    }

    private let storage: UserDefaults
    private let defaultValues: DefaultValues

    init(
        storage: UserDefaults = .standard,
        defaultValues: DefaultValues
    ) {
        self.storage = storage
        self.defaultValues = defaultValues
    }

    var backendURL: String {
        get { storage.string(forKey: Key.backendURL) ?? defaultValues.backendURL }
        set { storage.set(newValue, forKey: Key.backendURL) }
    }

    var provider: Provider {
        get {
            Provider(
                id: storage.string(forKey: Key.providerId) ?? "default",
                name: storage.string(forKey: Key.providerName) ?? "default"
            )
        }
        set {
            storage.set(newValue.id, forKey: Key.providerId)
            storage.set(newValue.name, forKey: Key.providerName)
        }
    }

    var showPayments: Bool {
        get { storage.value(forKey: Key.showPayments) as? Bool ?? true }
        set { storage.set(newValue, forKey: Key.showPayments) }
    }

    var paymentsUrl: String {
        get { storage.string(forKey: Key.paymentsURL) ?? "" }
        set { storage.set(newValue, forKey: Key.paymentsURL) }
    }

    var showChat: Bool {
        get { storage.value(forKey: Key.showChat) as? Bool ?? false }
        set { storage.set(newValue, forKey: Key.showChat) }
    }

    var chatUrl: String {
        get { storage.string(forKey: Key.chatURL) ?? "" }
        set { storage.set(newValue, forKey: Key.chatURL) }
    }

    var supportPhone: String {
        get { storage.string(forKey: Key.supportPhone) ?? "" }
        set { storage.set(newValue, forKey: Key.supportPhone) }
    }

    var chatId: String {
        get { storage.value(forKey: Key.chatId) as? String ?? "" }
        set { storage.set(newValue, forKey: Key.chatId) }
    }

    var chatDomain: String {
        get { storage.value(forKey: Key.chatDomain) as? String ?? "" }
        set { storage.set(newValue, forKey: Key.chatDomain) }
    }

    var chatToken: String {
        get { storage.value(forKey: Key.chatToken) as? String ?? "" }
        set { storage.set(newValue, forKey: Key.chatToken) }
    }

    var showCityCams: Bool {
        get { storage.value(forKey: Key.showCityCams) as? Bool ?? false }
        set { storage.set(newValue, forKey: Key.showCityCams) }
    }

    var phonePrefix: String {
        get { storage.value(forKey: Key.phonePrefix) as? String ?? defaultValues.phonePrefix }
        set { storage.set(newValue, forKey: Key.phonePrefix) }
    }

    var phonePattern: String {
        get { storage.value(forKey: Key.phonePattern) as? String ?? defaultValues.phonePattern }
        set { storage.set(newValue, forKey: Key.phonePattern) }
    }

    var guestAccessModeOnOnly: Bool {
        get { storage.value(forKey: Key.guestAccessMode) as? Bool ?? true }
        set { storage.set(newValue, forKey: Key.guestAccessMode) }
    }

    var timeZone: String {
        get { storage.value(forKey: Key.timeZone) as? String ?? defaultValues.timeZone }
        set { storage.set(newValue, forKey: Key.timeZone) }
    }

    var cctvView: String {
        get { storage.value(forKey: Key.cctvView) as? String ?? defaultValues.cctvView }
        set { storage.set(newValue, forKey: Key.cctvView) }
    }

    var entrancesView: String {
        get { storage.value(forKey: Key.entrancesView) as? String ?? defaultValues.entrancesView }
        set { storage.set(newValue, forKey: Key.entrancesView) }
    }

    var activeTab: String {
        get { storage.value(forKey: Key.activeTab) as? String ?? defaultValues.activeTab }
        set { storage.set(newValue, forKey: Key.activeTab) }
    }

    var issuesVersion: String {
        get { storage.value(forKey: Key.issuesVersion) as? String ?? "1" }
        set { storage.set(newValue, forKey: Key.issuesVersion) }
    }

    var eventsTrackingEnabled: Bool {
        get { storage.value(forKey: Key.eventsTrackingEnabled) as? Bool ?? false }
        set { storage.set(newValue, forKey: Key.eventsTrackingEnabled) }
    }

    var showStories: Bool {
        get { storage.value(forKey: Key.showStories) as? Bool ?? false }
        set { storage.set(newValue, forKey: Key.showStories) }
    }

    var stunUrl: String? {
        get { storage.string(forKey: Key.stunURL) }
        set { set(newValue, forKey: Key.stunURL) }
    }

    var nameValidationPattern: NameValidationPattern? {
        get { decode(NameValidationPattern.self, forKey: Key.nameValidationPattern) }
        set { encode(newValue, forKey: Key.nameValidationPattern) }
    }

    var deliveryTabsConfig: DeliveryTabsConfig? {
        get { decode(DeliveryTabsConfig.self, forKey: Key.deliveryTabsConfig) }
        set { encode(newValue, forKey: Key.deliveryTabsConfig) }
    }

    var phoneLengthWithoutPrefix: Int {
        phonePattern.filter { $0 == "#" }.count
    }

    var phoneLengthWithPrefix: Int {
        phoneLengthWithoutPrefix + phonePrefix.count + 1
    }

    func setPhonePattern(_ value: String?) {
        guard let value else {
            return
        }

        let valueRange = NSRange(value.startIndex ..< value.endIndex, in: value)

        guard let regex = try? NSRegularExpression(pattern: #"^\+?(?<prefix>\d+)\s*(?<pattern>.*)$"#),
              let match = regex.firstMatch(in: value, range: valueRange) else {
            return
        }

        if let prefixRange = Range(match.range(withName: "prefix"), in: value) {
            phonePrefix = String(value[prefixRange])
        }
        if let patternRange = Range(match.range(withName: "pattern"), in: value) {
            phonePattern = String(value[patternRange])
        }
    }

    private func set(_ value: String?, forKey key: String) {
        guard let value else {
            storage.removeObject(forKey: key)
            return
        }

        storage.set(value, forKey: key)
    }

    private func encode<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value else {
            storage.removeObject(forKey: key)
            return
        }

        storage.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = storage.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }
}
