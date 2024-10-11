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
private let showPaymentsKey = "showPayments"
private let paymentsUrlKey = "paymentsUrl"
private let supportPhoneKey = "supportPhoneKey"
private let centraScreenUrlKey = "centraScreenUrl"
private let intercomScreenUrlKey = "intercomScreenUrl"
private let activeTabKey = "activeTab"

class AccessService {
    
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
        case .phoneNumber: return .phoneNumber
        case .smsCode(let phoneNumber): return .pinCode(phoneNumber: phoneNumber, isInitial: false)
        case .userName: return .userName(preloadedName: clientName)
        case .main: return .main
        case let .authByOutgoingCall(phoneNumber, confirmPhoneNumber):
            return .authByOutgoingCall(
                phoneNumber: phoneNumber,
                confirmPhoneNumber: confirmPhoneNumber
            )
        case let .authByMobileProvider(phoneNumber, requestId):
            return .authByMobileProvider(phoneNumber: phoneNumber, requestId: requestId)
        }
    }
    
    var backendURL: String {
        get {
            #if DEBUG
            Constants.debugBackendURL
//            UserDefaults.standard.string(forKey: backendURLKey) ?? Constants.debugBackendURL
            #else
            Constants.defaultBackendURL
            #endif
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: backendURLKey)
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
    
    var supportPhone: String {
        get {
            UserDefaults.standard.string(forKey: supportPhoneKey) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: supportPhoneKey)
        }
    }
    
    var centraScreenUrl: String {
        get {
            UserDefaults.standard.string(forKey: centraScreenUrlKey) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: centraScreenUrlKey)
        }
    }
    
    var intercomScreenUrl: String {
        get {
            UserDefaults.standard.string(forKey: intercomScreenUrlKey) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: intercomScreenUrlKey)
        }
    }
    
    var activeTab: String {
        get {
            UserDefaults.standard.string(forKey: activeTabKey) ?? "centra"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: activeTabKey)
        }
    }
    
    func logout() {
        appState = .phoneNumber
        accessToken = nil
        clientName = nil
        clientPhoneNumber = nil
        #if DEBUG
        backendURL = Constants.debugBackendURL
        #elseif RELEASE
        backendURL = Constants.defaultBackendURL
        #endif
        showPayments = true
        paymentsUrl = ""
        supportPhone = ""
        centraScreenUrl = ""
        intercomScreenUrl = ""
        activeTab = "centra"
        
        NotificationCenter.default.post(name: .init("UserLoggedOut"), object: nil)
    }
    
}
