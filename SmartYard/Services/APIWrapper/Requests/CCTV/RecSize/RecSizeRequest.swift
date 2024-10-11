//
//  RecSizeRequest.swift
//  SmartYard
//
//  Created by devcentra on 14.11.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation

struct RecSizeRequest {
    
    let accessToken: String
    let id: Int
    let from: String
    let to: String
    
}

extension RecSizeRequest {
    
    var requestParameters: [String: Any] {
        return [
            "id": id,
            "from": from,
            "to": to
        ]
    }
    
}
