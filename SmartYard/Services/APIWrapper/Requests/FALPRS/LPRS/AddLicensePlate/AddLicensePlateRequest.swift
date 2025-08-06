//
//  AddLicensePlateRequest.swift
//  SmartYard
//
//  Created by Александр Попов on 09.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

struct AddLicensePlateRequest {
    
    let accessToken: String
    let flatId: Int
    let number: String // License plate number (ENGLISH)
    
}

extension AddLicensePlateRequest {
    
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId,
            "number": number
        ]
    }
    
}
