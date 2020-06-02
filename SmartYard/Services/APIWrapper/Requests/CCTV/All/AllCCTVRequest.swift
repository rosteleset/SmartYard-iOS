//
//  AllCCTVRequest.swift
//  SmartYard
//
//  Created by admin on 01.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct AllCCTVRequest {
    
    let accessToken: String
    let houseId: String?
    
}

extension AllCCTVRequest {
    
    var requestParameters: [String: Any] {
        var params = [String: Any]()
        
        if let houseId = houseId {
            params["houseId"] = houseId
        }
        
        return params
    }
    
}
