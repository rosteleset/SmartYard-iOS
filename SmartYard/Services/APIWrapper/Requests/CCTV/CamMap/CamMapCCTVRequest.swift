//
//  CamMapCCTVRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 27.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct CamMapCCTVRequest {
    
    let accessToken: String
}

extension CamMapCCTVRequest {
    var requestParameters: [String: Any] {
        return [:]
    }
}
