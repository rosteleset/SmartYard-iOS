//
//  AccessService.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

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

class AccessService {
    static let shared = AccessService()
    
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
        switch appState {
        case .onboarding: return .onboarding
        case .selectProvider: return .selectProvider
        case .phoneNumber: return .phoneNumber
        case .smsCode(let phoneNumber): return .pinCode(phoneNumber: phoneNumber, isInitial: false)
        case .userName: return .userName(preloadedName: clientName)
        case .main: return .main
        case .authByOutgoingCall(let phoneNumber, let confirmPhoneNumber):
            return .authByOutgoingCall(
                phoneNumber: phoneNumber,
                confirmPhoneNumber: confirmPhoneNumber
            )
        }
    }
    
    var backendURL: String {
        get {
            UserDefaults.standard.string(forKey: backendURLKey) ?? Constants.defaultBackendURL ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: backendURLKey)
        }
    }
    
    var providerId: String {
        get {
            UserDefaults.standard.string(forKey: providerIdKey) ?? "default"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: providerIdKey)
        }
    }
    
    var providerName: String {
        get {
            UserDefaults.standard.string(forKey: providerNameKey) ?? "default"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: providerNameKey)
        }
    }
    
    var showPayments: Bool {
        get {
            UserDefaults.standard.value(forKey: showPaymentsKey)  as? Bool ?? true
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
            UserDefaults.standard.value(forKey: showChatKey)  as? Bool ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: showChatKey)
        }
    }
    
    var chatId: String {
        get {
            UserDefaults.standard.value(forKey: chatIdKey)  as? String ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: chatIdKey)
        }
    }
    
    var chatDomain: String {
        get {
            UserDefaults.standard.value(forKey: chatDomainKey)  as? String ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: chatDomainKey)
        }
    }
    
    var chatToken: String {
        get {
            UserDefaults.standard.value(forKey: chatTokenKey)  as? String ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: chatTokenKey)
        }
    }
    
    var showCityCams: Bool {
        get {
            UserDefaults.standard.value(forKey: showCityCamsKey)  as? Bool ?? false
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: showCityCamsKey)
        }
    }
    
    var phonePrefix: String {
        get {
            UserDefaults.standard.value(forKey: phonePrefixKey)  as? String ?? Constants.defaultPhonePrefix
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: phonePrefixKey)
        }
    }
    
    var phonePattern: String {
        get {
            UserDefaults.standard.value(forKey: phonePatternKey)  as? String ?? Constants.defaultPhonePattern
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: phonePatternKey)
        }
    }
    
    var phoneLengthWithoutPrefix: Int {
            phonePattern.count(of: "#")
    }
    
    var phoneLengthWithPrefix: Int {
        phoneLengthWithoutPrefix + phonePrefix.count + 1
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
    
    func logout() {
        appState = Constants.defaultBackendURL.isNilOrEmpty ? .selectProvider : .phoneNumber
        accessToken = nil
        clientName = nil
        clientPhoneNumber = nil
        backendURL = Constants.defaultBackendURL ?? ""
        providerId = "default"
        providerName = "default"
        showPayments = true
        paymentsUrl = ""
        supportPhone = ""
        showChat = false
        chatId = ""
        chatDomain = ""
        chatToken = ""
        showCityCams = false
        phonePrefix = "7"
        phonePattern = "(###) ###-##-##"
        
        NotificationCenter.default.post(name: .init("UserLoggedOut"), object: nil)
    }
    
}
