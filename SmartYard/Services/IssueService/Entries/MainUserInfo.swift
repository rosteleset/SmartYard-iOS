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
        return "ФИО: \(fullName)\nТелефон: \(phoneNumber)\nАдрес, введённый пользователем: \(address)"
    }
    
}
