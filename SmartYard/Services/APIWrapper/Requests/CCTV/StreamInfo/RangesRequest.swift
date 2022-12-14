//
//  RangesRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 22.11.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation

struct RangesRequest {
    let cameraId: Int
    let accessToken: String
}

extension RangesRequest {
    
    var requestParameters: [String: Any] {
        return ["cameraId": cameraId]
    }
    
}
