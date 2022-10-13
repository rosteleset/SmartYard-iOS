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
        case .authByOutgoingCall(let phoneNumber, let confirmPhoneNumber):
            return .authByOutgoingCall(
                phoneNumber: phoneNumber,
                confirmPhoneNumber: confirmPhoneNumber
            )
        }
    }
    
    var backendURL: String {
        get {
            UserDefaults.standard.string(forKey: backendURLKey) ?? Constants.defaultBackendURL
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
            UserDefaults.standard.string(forKey: supportPhoneKey) ?? "+7(4752)429999"
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: supportPhoneKey)
        }
    }
    
    func logout() {
        appState = .phoneNumber
        accessToken = nil
        clientName = nil
        clientPhoneNumber = nil
        backendURL = Constants.defaultBackendURL
        showPayments = true
        paymentsUrl = ""
        supportPhone = "+7(4752)429999"
        
        NotificationCenter.default.post(name: .init("UserLoggedOut"), object: nil)
    }
    
}
