//
//  LikePersonFacesRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct LikePersonFaceRequest {
    
    let accessToken: String
    let event: String
    
}

extension LikePersonFaceRequest {
    
    var requestParameters: [String: Any] {
        return ["event": "\(event)"]
    }
    
}
