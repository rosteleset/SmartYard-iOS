//
//  RemoveLicensePlateRequest.swift
//  SmartYard
//
//  Created by Александр Попов on 09.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

struct RemoveLicensePlateRequest {
    
    let accessToken: String
    let flatId: Int
    let number: String // License plate number (ENGLISH)
    
}

extension RemoveLicensePlateRequest {
    
    var requestParameters: [String: Any] {
        return [
            "flatId": flatId,
            "number": number
        ]
    }
    
}
