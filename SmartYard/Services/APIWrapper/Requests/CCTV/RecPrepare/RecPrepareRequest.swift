//
//  RecPrepareRequest.swift
//  SmartYard
//
//  Created by admin on 11.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct RecPrepareRequest {
    
    let accessToken: String
    let id: Int
    let from: String
    let to: String
    
}

extension RecPrepareRequest {
    
    var requestParameters: [String: Any] {
        return [
            "id": id,
            "from": from,
            "to": to
        ]
    }
    
}
