//
//  MainUserInfo.swift
//  SmartYard
//
//  Created by Mad Brains on 28.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct MainUserInfo {
    
    let fullName: String
    let phoneNumber: String
    
    var clientId: String?
    var address: String
    
    func convertToString() -> String {
        let text = String.localizedStringWithFormat(
            L10n.Services.Request.mainUserInfoFormat,
            "\(fullName)",
            "\(phoneNumber)",
            "\(address)"
        )
        return text
    }
    
}
