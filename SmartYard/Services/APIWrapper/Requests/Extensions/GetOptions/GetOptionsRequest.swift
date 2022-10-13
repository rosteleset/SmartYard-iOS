//
//  GetExtensionRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation

struct GetOptionsRequest {
    let accessToken: String
}

extension GetOptionsRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
