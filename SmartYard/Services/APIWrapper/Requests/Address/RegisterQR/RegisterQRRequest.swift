//
//  RegisterQRRequest.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct RegisterQRRequest {
    
    let accessToken: String
    let qr: String
    
}

extension RegisterQRRequest {
    
    var requestParameters: [String: Any] {
        return [
            "QR": qr
        ]
    }
    
}
