//
//  Constants.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import CoreLocation

enum Constants {
    
    static let phoneLengthWithoutPrefix = 10
    static let phoneLengthWithPrefix = 12
    static let pinLength = 4
    static let merchant = "centra"
    static let appstoreUrl = "appstoreUrl"
    static let yandexApiKey = "YOU_NEED_TO_CHANGE_THIS"
    static let defaultBackendURL = "defaultBackendURL"
    static let mapBoxPublicKey = "mapBoxPublicKey"
    static let sberbankAPILogin = "sberbankAPILogin"
    static let sberbankAPIPassword = "sberbankAPIPassword"
    static let sberbankSuccessReturnURL = "centra://"
    static let sberbankFailureReturnURL = "sberbankFailureReturnURL"
    static let defaultMapCenterCoordinates = CLLocationCoordinate2D(latitude: 53.757547, longitude: 87.136044)
    static let socketDebugURL = "wss://chatwoot.mycentra.ru/cable"
    static let socketMasterURL = "wss://chatwoot.mycentra.ru/cable"

    enum Chat {
        static let token = "YOU_NEED_TO_CHANGE_THIS"
        static let id = "id"
        static let domain = "intercom-mobile-api.mycentra.ru"
    }
    
}
