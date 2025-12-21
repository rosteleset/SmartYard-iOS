//
//  GetExtensionRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation

struct GetExtensionRequest {
    let accessToken: String
    let extId: String
}

extension GetExtensionRequest {
    
    var requestParameters: [String: Any] {
        return ["extId": extId]
    }
    
}
