//
//  ResetCodeRequest.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct ResetCodeRequest {
    
    let accessToken: String
    let flatId: String
    
}

extension ResetCodeRequest {
    
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId
        ]
    }
    
}
