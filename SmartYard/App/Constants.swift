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
    
    static let pinLength = 4
    static let merchant = "YOU_NEED_TO_CHANGE_THIS"
    static let appstoreUrl = "YOU_NEED_TO_CHANGE_THIS"
    // Set your custom backend base URL here. ex: "https://your.domain/mobile" or set it nil for select it at the first time.
    static let defaultBackendURL: String? = nil // "https://sbca.lanta.me/mobile"
    static let provListURL = "https://isdn.sesameware.com/providers.json"
    static let mapBoxPublicKey = "YOU_NEED_TO_CHANGE_THIS"
    static let defaultMapCenterCoordinates = CLLocationCoordinate2D(latitude: 52.675463000000001, longitude: 41.465411000000003)
    static let defaultPhonePrefix = "7"
    static let defaultPhonePattern = "(###) ###-##-##"
    static let defaultTimeZone = "Europe/Moscow"
    static let showDeleteAccountButton = false
    static let isDarkModeEnabled = false // set 'true' if you have Dark Mode
}
