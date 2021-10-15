//
//  LoginRequest.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct AddMyPhoneRequest {
    
    let accessToken: String
    let login: String
    let password: String
    let comment: String?
    let useForNotifications: Bool?
    
}

extension AddMyPhoneRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "login": login,
            "password": password
        ]
        
        if let comment = comment {
            params["comment"] = comment
        }
        
        if let notification = useForNotifications {
            params["notification"] = notification ? "t" : "f"
        }
        
        return params
    }
    
}
