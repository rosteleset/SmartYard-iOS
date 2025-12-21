//
//  GetLicensePlatesRequest.swift
//  SmartYard
//
//  Created by Александр Попов on 09.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

struct GetLicensePlatesRequest {
    
    let accessToken: String
    let flatId: Int
    
}

extension GetLicensePlatesRequest {
    
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId
        ]
    }
    
}
