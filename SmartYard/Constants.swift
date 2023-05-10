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
    static let appstoreUrl = "https://apps.apple.com/ru/app/centra-%D0%B4%D0%BE%D0%BC/id6445887550"
    static let yandexApiKey = "YOU_NEED_TO_CHANGE_THIS"
    static let defaultBackendURL = "https://intercom-mobile-api.mycentra.ru"
//    static let defaultBackendURL = "http://192.168.15.15"
    static let mapBoxPublicKey = "sk.eyJ1IjoibGVoYTMwNzciLCJhIjoiY2xlb3plbDBiMDN6MzN0cnVrcGQwNHBjOCJ9.dyPywFTtJm4zGw12GHmidw"
    static let sberbankAPILogin = "qwerty"
    static let sberbankAPIPassword = "zaq12wsx"
    static let sberbankSuccessReturnURL = "centra://"
    static let sberbankFailureReturnURL = "https://mycentra.ru"
    static let defaultMapCenterCoordinates = CLLocationCoordinate2D(latitude: 53.757547, longitude: 87.136044)
    static let socketDebugURL = "wss://chatwoot.mycentra.ru/cable"
    static let socketMasterURL = "wss://chatwoot.mycentra.ru/cable"

    enum Chat {
        static let token = "YOU_NEED_TO_CHANGE_THIS"
        static let id = "7087c1e6f6d8506d95e876dbc48a85c6"
        static let domain = "intercom-mobile-api.mycentra.ru"
    }
    
}
