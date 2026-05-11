//
//  AccessService.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxRelay

private let appStateKey = "appState"
private let accessTokenKey = "accessToken"
private let voipTokenKey = "voipToken"
private let prefersVoipForCallsKey = "prefersVoipForCalls"
private let prefersSpeakerForCallsKey = "prefersSpeakerForCalls"
private let clientNameKey = "clientName"
private let clientPhoneNumberKey = "clientPhoneNumber"
private let backendURLKey = "backendURL"
private let providerIdKey = "providerId"
private let providerNameKey = "providerNameKey"
private let showPaymentsKey = "showPayments"
private let showChatKey = "showChat"
private let chatIdKey = "chatId"
private let chatDomainKey = "chatDomain"
private let chatTokenKey = "chatToken"
private let showCityCamsKey = "showCityCams"
private let paymentsUrlKey = "paymentsUrl"
private let chatUrlKey = "chatUrl"
private let supportPhoneKey = "supportPhoneKey"
private let phonePrefixKey = "phonePrefixKey"
private let phonePatternKey = "phonePatternKey"
private let guestAccessModeKey = "guestAccessKey"
private let timeZoneKey = "timeZoneKey"
private let cctvViewKey = "cctvViewKey"
private let entrancesViewKey = "entrancesViewKey"
private let showListKey = "showListKey"
private let activeTabKey = "activeTabKey"
private let issuesVersionKey = "issuesVersionKey"
private let userPreferredAddressOrderKey = "userPreferredAddressOrderKey"
private let nameValidationPatternKey = "nameValidationPatternKey"
private let deliveryTabsConfigKey = "deliveryTabsConfigKey"

// swiftlint:disable:next type_body_length
final class AccessService {
    static let shared = AccessService()

    let optionsUpdated = PublishRelay<Void>()
    let providerChanged = PublishRelay<APIProvider>()
    let backendURLChanged = PublishRelay<String>()
    let sessionAuthorized = PublishRelay<Void>()
    
    struct Provider: Equatable {
        let id: String
        let name: String
    }

    var appState: AppState {
        get {
            UserDefaults.standard.object(AppState.self, with: appStateKey) ?? .onboarding
        }
        set {
            UserDefaults.standard.set(object: newValue, forKey: appStateKey)
        }
    }
    
    var accessToken: String? {
        get {
            UserDefaults.standard.string(forKey: accessTokenKey)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
                return
            }
            
            UserDefaults.standard.setValue(newValue, forKey: accessTokenKey)
        }
    }
    
    var voipToken: String? {
        get {
            UserDefaults.standard.string(forKey: voipTokenKey)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: voipTokenKey)
                return
            }
            
            UserDefaults.standard.setValue(newValue, forKey: voipTokenKey)
        }
    }
    
    var prefersVoipForCalls: Bool {
        get {
            UserDefaults.standard.value(forKey: prefersVoipForCallsKey) as? Bool ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: prefersVoipForCallsKey)
        }
    }
    
    var prefersSpeakerForCalls: Bool {
        get {
            UserDefaults.standard.value(forKey: prefersSpeakerForCallsKey) as? Bool ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: prefersSpeakerForCallsKey)
        }
    }
    
    var clientName: APIClientName? {
        get {
            UserDefaults.standard.object(APIClientName.self, with: clientNameKey)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: clientNameKey)
                return
            }
            
            UserDefaults.standard.set(object: newValue, forKey: clientNameKey)
        }
    }
    
    var clientPhoneNumber: String? {
        get {
            UserDefaults.standard.string(forKey: clientPhoneNumberKey)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: clientPhoneNumberKey)
                return
            }
            
            UserDefaults.standard.setValue(newValue, forKey: clientPhoneNumberKey)
        }
    }
    
    var routeForCurrentState: AppRoute {
        if let token = accessToken, !token.isEmpty {
            return .main
        }
        
        switch appState {
        case .onboarding: return .onboarding
        case .selectProvider: return .selectProvider
        case .phoneNumber: return .phoneNumber
        case .smsCode(let phoneNumber): return .pinCode(phoneNumber: phoneNumber, isInitial: false, useFlashCall: false)
        case .userName: return .userName(preloadedName: clientName)
        case .main: return .main
        case let .authByOutgoingCall(phoneNumber, confirmPhoneNumber):
            return .authByOutgoingCall(
                phoneNumber: phoneNumber,
                confirmPhoneNumber: confirmPhoneNumber
            )
        case .flashCall(let phoneNumber): return .pinCode(phoneNumber: phoneNumber, isInitial: false, useFlashCall: true)
        case .offline: return .offline
        }
    }
    
    var backendURL: String {
        get {
            UserDefaults.standard.string(forKey: backendURLKey) ?? Constants.defaultBackendURL ?? "https://127.0.0.1/mobile"
        }
        set {
            if newValue == backendURL { return }
            UserDefaults.standard.setValue(newValue, forKey: backendURLKey)
            backendURLChanged.accept(newValue)
        }
    }
    
    var provider: Provider {
        get {
            Provider(
                id: UserDefaults.standard.string(forKey: providerIdKey) ?? "default",
                name: UserDefaults.standard.string(forKey: providerNameKey) ?? "default"
            )
        }
        set {
            if newValue == provider { return }
                
            UserDefaults.standard.setValue(newValue.id, forKey: providerIdKey)
            UserDefaults.standard.setValue(newValue.name, forKey: providerNameKey)
            providerChanged.accept(
                APIProvider(
                    id: newValue.id,
                    name: newValue.name,
                    baseUrl: backendURL,
                    order: nil
                )
            )
        }
    }
    
    var showPayments: Bool {
        get {
            UserDefaults.standard.value(forKey: showPaymentsKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: showPaymentsKey)
        }
    }
    
    var paymentsUrl: String {
        get {
            UserDefaults.standard.string(forKey: paymentsUrlKey) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: paymentsUrlKey)
        }
    }
    
    var chatUrl: String {
        get {
            UserDefaults.standard.string(forKey: chatUrlKey) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: chatUrlKey)
        }
    }
    
    var supportPhone: String {
        get {
            UserDefaults.standard.string(forKey: supportPhoneKey) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: supportPhoneKey)
        }
    }
    
    var showChat: Bool {
        get {
            UserDefaults.standard.value(forKey: showChatKey) as? Bool ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: showChatKey)
        }
    }
    
    var chatId: String {
        get {
            UserDefaults.standard.value(forKey: chatIdKey) as? String ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: chatIdKey)
        }
    }
    
    var chatDomain: String {
        get {
            UserDefaults.standard.value(forKey: chatDomainKey) as? String ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: chatDomainKey)
        }
    }
    
    var chatToken: String {
        get {
            UserDefaults.standard.value(forKey: chatTokenKey) as? String ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: chatTokenKey)
        }
    }
    
    var showCityCams: Bool {
        get {
            UserDefaults.standard.value(forKey: showCityCamsKey) as? Bool ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: showCityCamsKey)
        }
    }
    
    var showList: Bool {
        get {
            UserDefaults.standard.value(forKey: showListKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: showListKey)
        }
    }
    
    var phonePrefix: String {
        get {
            UserDefaults.standard.value(forKey: phonePrefixKey) as? String ?? Constants.defaultPhonePrefix
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: phonePrefixKey)
        }
    }
    
    var phonePattern: String {
        get {
            UserDefaults.standard.value(forKey: phonePatternKey) as? String ?? Constants.defaultPhonePattern
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: phonePatternKey)
        }
    }
    
    var guestAccessModeOnOnly: Bool {
        get {
            UserDefaults.standard.value(forKey: guestAccessModeKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: guestAccessModeKey)
        }
    }
    
    var cctvView: String {
        get {
            UserDefaults.standard.value(forKey: cctvViewKey) as? String ?? "list"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: cctvViewKey)
        }
    }

    var entrancesView: String {
        get {
            UserDefaults.standard.value(forKey: entrancesViewKey) as? String ?? APIOptions.EntrancesViewType.list.rawValue
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: entrancesViewKey)
        }
    }
    
    var activeTab: String {
        get {
            UserDefaults.standard.value(forKey: activeTabKey) as? String ?? APIOptions.TabNames.addresses.rawValue
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: activeTabKey)
        }
    }
    
    var timeZone: String {
        get {
            UserDefaults.standard.value(forKey: timeZoneKey) as? String ?? Constants.defaultTimeZone
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: timeZoneKey)
        }
    }
    
    var issuesVersion: String {
        get {
            UserDefaults.standard.value(forKey: issuesVersionKey) as? String ?? "1"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: issuesVersionKey)
        }
    }
    
    var userPreferredAddressOrder: [String] {
        get {
            UserDefaults.standard.value(forKey: userPreferredAddressOrderKey) as? [String] ?? []
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: userPreferredAddressOrderKey)
        }
    }
    
    var phoneLengthWithoutPrefix: Int {
        phonePattern.count(of: "#")
    }
    
    var phoneLengthWithPrefix: Int {
        phoneLengthWithoutPrefix + phonePrefix.count + 1
    }

    var nameValidationPattern: NameValidationPattern? {
        get {
            decode(NameValidationPattern.self, from: nameValidationPatternKey)
        }
        set {
            encodeAndSave(newValue, to: nameValidationPatternKey)
        }
    }

    var deliveryTabsConfig: DeliveryTabsConfig? {
        get {
            decode(DeliveryTabsConfig.self, from: deliveryTabsConfigKey)
        }
        set {
            encodeAndSave(newValue, to: deliveryTabsConfigKey)
        }
    }

    func setPhonePattern(_ from: String? = nil) {
        guard let from = from else {
            return
        }
        
        let fromRange = NSRange(from.startIndex ..< from.endIndex, in: from)
        
        do {
            let regex = try NSRegularExpression(pattern: #"^\+?(?<prefix>\d+)\s*(?<pattern>.*)$"#)
            let matches = regex.matches(in: from, range: fromRange)
            
            guard let match = matches.first else {
                return
            }
            
            if let prefixRange = Range(match.range(withName: "prefix"), in: from) {
                phonePrefix = String(from[prefixRange])
            }
            if let patternRange = Range(match.range(withName: "pattern"), in: from) {
                phonePattern = String(from[patternRange])
            }
        } catch _ {
            return
        }
    }

    func authorizeSession(token: String, name: APIClientName?, phone: String) {
        accessToken = token
        clientName = name
        clientPhoneNumber = phone

        sessionAuthorized.accept(())
    }

    func logout() {
        accessToken = nil
        clientName = nil
        clientPhoneNumber = nil
        backendURL = Constants.defaultBackendURL ?? "https://127.0.0.1/mobile"
        appState = Constants.defaultBackendURL.isNilOrEmpty ? .selectProvider : .phoneNumber
        provider = Provider(id: "default", name:"default")
        showPayments = true
        paymentsUrl = ""
        supportPhone = ""
        showChat = false
        issuesVersion = ""
        chatId = ""
        chatDomain = ""
        chatToken = ""
        showCityCams = false
        userPreferredAddressOrder = []
        phonePrefix = Constants.defaultPhonePrefix
        phonePattern = Constants.defaultPhonePattern
        nameValidationPattern = nil

        NotificationCenter.default.post(name: .init("UserLoggedOut"), object: nil)
    }
    
}

extension AccessService {

    private func encodeAndSave<T: Encodable>(_ newValue: T?, to key: String) {
        let defaults = UserDefaults.standard
        if let value = newValue {
            let data = try? JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func decode<T: Decodable>(_: T.Type, from key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }

}

extension AccessService {
    var hasValidToken: Bool { !(accessToken ?? "").isEmpty }
}
