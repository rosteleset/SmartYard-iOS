//
//  RecDownloadRequest.swift
//  SmartYard
//
//  Created by admin on 15.06.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation

struct RecDownloadRequest {
    
    let accessToken: String
    let id: Int
    
}

extension RecDownloadRequest {
    
    var requestParameters: [String: Any] {
        return ["id": id]
    }
    
}
