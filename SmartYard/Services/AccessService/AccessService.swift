//
//  AccessService.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation
import RxRelay

private let appStateKey = "appState"
private let voipTokenKey = "voipToken"
private let prefersVoipForCallsKey = "prefersVoipForCalls"
private let prefersSpeakerForCallsKey = "prefersSpeakerForCalls"
private let showListKey = "showListKey"
private let userPreferredAddressOrderKey = "userPreferredAddressOrderKey"

#if DEBUG
private let forceEventsTrackingEnabledForTesting = true
#endif

// swiftlint:disable:next type_body_length
final class AccessService {
    static let shared = AccessService()

    private let sessionStore: SessionStore
    private let operatorConfiguration: OperatorConfiguration

    let optionsUpdated = PublishRelay<Void>()
    let providerChanged = PublishRelay<APIProvider>()
    let backendURLChanged = PublishRelay<String>()
    let sessionAuthorized = PublishRelay<Void>()
    
    typealias Provider = OperatorConfiguration.Provider

    init(
        sessionStore: SessionStore = SessionStore(),
        operatorConfiguration: OperatorConfiguration = OperatorConfiguration(defaultValues: .live)
    ) {
        self.sessionStore = sessionStore
        self.operatorConfiguration = operatorConfiguration
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
            sessionStore.accessToken
        }
        set {
            sessionStore.accessToken = newValue
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
            sessionStore.clientName
        }
        set {
            sessionStore.clientName = newValue
        }
    }
    
    var clientPhoneNumber: String? {
        get {
            sessionStore.clientPhoneNumber
        }
        set {
            sessionStore.clientPhoneNumber = newValue
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
            operatorConfiguration.backendURL
        }
        set {
            if newValue == backendURL { return }
            operatorConfiguration.backendURL = newValue
            backendURLChanged.accept(newValue)
        }
    }
    
    var provider: Provider {
        get {
            operatorConfiguration.provider
        }
        set {
            if newValue == provider { return }

            operatorConfiguration.provider = newValue
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
            operatorConfiguration.showPayments
        }
        set {
            operatorConfiguration.showPayments = newValue
        }
    }
    
    var paymentsUrl: String {
        get {
            operatorConfiguration.paymentsUrl
        }
        set {
            operatorConfiguration.paymentsUrl = newValue
        }
    }
    
    var chatUrl: String {
        get {
            operatorConfiguration.chatUrl
        }
        set {
            operatorConfiguration.chatUrl = newValue
        }
    }
    
    var supportPhone: String {
        get {
            operatorConfiguration.supportPhone
        }
        set {
            operatorConfiguration.supportPhone = newValue
        }
    }
    
    var showChat: Bool {
        get {
            operatorConfiguration.showChat
        }
        set {
            operatorConfiguration.showChat = newValue
        }
    }
    
    var chatId: String {
        get {
            operatorConfiguration.chatId
        }
        set {
            operatorConfiguration.chatId = newValue
        }
    }
    
    var chatDomain: String {
        get {
            operatorConfiguration.chatDomain
        }
        set {
            operatorConfiguration.chatDomain = newValue
        }
    }
    
    var chatToken: String {
        get {
            operatorConfiguration.chatToken
        }
        set {
            operatorConfiguration.chatToken = newValue
        }
    }
    
    var showCityCams: Bool {
        get {
            operatorConfiguration.showCityCams
        }
        set {
            operatorConfiguration.showCityCams = newValue
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
            operatorConfiguration.phonePrefix
        }
        set {
            operatorConfiguration.phonePrefix = newValue
        }
    }
    
    var phonePattern: String {
        get {
            operatorConfiguration.phonePattern
        }
        set {
            operatorConfiguration.phonePattern = newValue
        }
    }
    
    var guestAccessModeOnOnly: Bool {
        get {
            operatorConfiguration.guestAccessModeOnOnly
        }
        set {
            operatorConfiguration.guestAccessModeOnOnly = newValue
        }
    }
    
    var cctvView: String {
        get {
            operatorConfiguration.cctvView
        }
        set {
            operatorConfiguration.cctvView = newValue
        }
    }

    var entrancesView: String {
        get {
            operatorConfiguration.entrancesView
        }
        set {
            operatorConfiguration.entrancesView = newValue
        }
    }
    
    var activeTab: String {
        get {
            operatorConfiguration.activeTab
        }
        set {
            operatorConfiguration.activeTab = newValue
        }
    }
    
    var timeZone: String {
        get {
            operatorConfiguration.timeZone
        }
        set {
            operatorConfiguration.timeZone = newValue
        }
    }

    var stunUrl: String? {
        get {
            operatorConfiguration.stunUrl
        }
        set {
            operatorConfiguration.stunUrl = newValue
        }
    }
    
    var issuesVersion: String {
        get {
            operatorConfiguration.issuesVersion
        }
        set {
            operatorConfiguration.issuesVersion = newValue
        }
    }

    var eventsTrackingEnabled: Bool {
        get {
#if DEBUG
            if forceEventsTrackingEnabledForTesting { return true }
#endif
            return operatorConfiguration.eventsTrackingEnabled
        }
        set {
            operatorConfiguration.eventsTrackingEnabled = newValue
        }
    }

    var showStories: Bool {
        get {
            operatorConfiguration.showStories
        }
        set {
            operatorConfiguration.showStories = newValue
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
        operatorConfiguration.phoneLengthWithoutPrefix
    }
    
    var phoneLengthWithPrefix: Int {
        operatorConfiguration.phoneLengthWithPrefix
    }

    var nameValidationPattern: NameValidationPattern? {
        get {
            operatorConfiguration.nameValidationPattern
        }
        set {
            operatorConfiguration.nameValidationPattern = newValue
        }
    }

    var deliveryTabsConfig: DeliveryTabsConfig? {
        get {
            operatorConfiguration.deliveryTabsConfig
        }
        set {
            operatorConfiguration.deliveryTabsConfig = newValue
        }
    }

    func setPhonePattern(_ from: String? = nil) {
        operatorConfiguration.setPhonePattern(from)
    }

    func authorizeSession(token: String, name: APIClientName?, phone: String) {
        sessionStore.authorize(token: token, name: name, phone: phone)

        sessionAuthorized.accept(())
    }

    func logout() {
        sessionStore.clear()
        backendURL = Constants.defaultBackendURL ?? "https://127.0.0.1/mobile"
        appState = Constants.defaultBackendURL.isNilOrEmpty ? .selectProvider : .phoneNumber
        provider = Provider(id: "default", name: "default")
        showPayments = true
        paymentsUrl = ""
        supportPhone = ""
        showChat = false
        chatUrl = ""
        issuesVersion = ""
        chatId = ""
        chatDomain = ""
        chatToken = ""
        showCityCams = false
        eventsTrackingEnabled = false
        showStories = false
        userPreferredAddressOrder = []
        phonePrefix = Constants.defaultPhonePrefix
        phonePattern = Constants.defaultPhonePattern
        nameValidationPattern = nil

        NotificationCenter.default.post(name: .init("UserLoggedOut"), object: nil)
    }
    
}

extension AccessService {
    var hasValidToken: Bool { sessionStore.hasValidToken }
}

extension OperatorConfiguration.DefaultValues {
    static var live: Self {
        .init(
            backendURL: Constants.defaultBackendURL ?? "https://127.0.0.1/mobile",
            phonePrefix: Constants.defaultPhonePrefix,
            phonePattern: Constants.defaultPhonePattern,
            timeZone: Constants.defaultTimeZone,
            cctvView: APIOptions.CCTVViewType.list.rawValue,
            entrancesView: APIOptions.EntrancesViewType.list.rawValue,
            activeTab: APIOptions.TabNames.addresses.rawValue
        )
    }
}
