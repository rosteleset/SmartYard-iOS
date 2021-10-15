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
private let clientNameKey = "clientName"
private let clientPhoneNumberKey = "clientPhoneNumber"
private let backendURLKey = "backendURL"

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
    
    func logout() {
        appState = .phoneNumber
        accessToken = nil
        clientName = nil
        clientPhoneNumber = nil
        
        NotificationCenter.default.post(name: .init("UserLoggedOut"), object: nil)
    }
    
}
