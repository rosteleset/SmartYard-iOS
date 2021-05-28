//
//  OverviewCCTVRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct OverviewCCTVRequest {
    let accessToken: String
    let forceRefresh: Bool
}

extension OverviewCCTVRequest {
    
    var requestParameters: [String: Any] {
        let params = [String: Any]()
        
        return params
    }
    
}
