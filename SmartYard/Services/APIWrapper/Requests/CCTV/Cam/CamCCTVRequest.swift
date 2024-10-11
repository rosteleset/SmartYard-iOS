//
//  CamCCTVRequest.swift
//  SmartYard
//
//  Created by admin on 01.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct CamCCTVRequest {
    
    let accessToken: String
    let forceRefresh: Bool
    let camId: Int?
    
}

extension CamCCTVRequest {
    
    var requestParameters: [String: Any] {
        var params = [String: Any]()
        
        if let camId = camId {
            params["camId"] = camId
        }
        
        return params
    }
    
}
