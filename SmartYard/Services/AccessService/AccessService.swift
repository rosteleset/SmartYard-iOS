//
//  AccessService.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

private let accessTokenKey = "accessToken"
private let clientIdKey = "clientId"

class AccessService {
    
    var accessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: accessTokenKey)
        }
        set {
            return UserDefaults.standard.setValue(newValue, forKey: accessTokenKey)
        }
    }
    
    var clientId: String? {
        get {
            return UserDefaults.standard.string(forKey: clientIdKey)
        }
        set {
            return UserDefaults.standard.setValue(newValue, forKey: clientIdKey)
        }
    }
    
    func logout() {
        accessToken = nil
        clientId = nil
    }
    
}
