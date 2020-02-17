//
//  AccessService.swift
//  SmartYard
//
//  Created by admin on 04/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

private let accessTokenKey = "accessToken"
private let clientNameKey = "clientName"

class AccessService {
    
    var accessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: accessTokenKey)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
                return
            }
            
            UserDefaults.standard.setValue(newValue, forKey: accessTokenKey)
        }
    }
    
    var clientName: APIClientName? {
        get {
            return UserDefaults.standard.object(APIClientName.self, with: clientNameKey)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: clientNameKey)
                return
            }
            
            UserDefaults.standard.set(object: newValue, forKey: clientNameKey)
        }
    }
    
    func logout() {
        accessToken = nil
        clientName = nil
    }
    
}
