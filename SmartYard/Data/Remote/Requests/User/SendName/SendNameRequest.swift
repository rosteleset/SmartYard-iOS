//
//  SendNameRequest.swift
//  SmartYard
//
//  Created by admin on 17/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct SendNameRequest {
    
    let accessToken: String
    let name: String
    let patronymic: String?
    
}

extension SendNameRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "name": name
        ]
        
        if let patronymic = patronymic {
            params["patronymic"] = patronymic
        }
        
        return params
    }
    
}
