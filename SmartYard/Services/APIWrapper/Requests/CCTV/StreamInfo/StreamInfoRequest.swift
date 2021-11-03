//
//  StreamInfoRequest.swift
//  SmartYard
//
//  Created by admin on 08.07.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct StreamInfoRequest {
    
    let cameraUrl: String
    let from: Int
    let token: String
    
}

extension StreamInfoRequest {
    
    var requestParameters: [String: Any] {
        return ["from": from, "token": token]
    }
    
}
