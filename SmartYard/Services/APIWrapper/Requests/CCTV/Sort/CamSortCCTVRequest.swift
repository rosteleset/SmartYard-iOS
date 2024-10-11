//
//  CamSortCCTVRequest.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 28.03.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct CamSortCCTVRequest {
    
    let accessToken: String
    let sort: [Int]
}

extension CamSortCCTVRequest {
    
    var requestParameters: [String: Any] {
        return [
            "sort": sort
        ]
    }
    
}
