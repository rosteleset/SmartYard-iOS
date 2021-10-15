//
//  DisLikePersonFacesRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct DisLikePersonFaceRequest {
    let accessToken: String
    let event: String
}

extension DisLikePersonFaceRequest {
    var requestParameters: [String: Any] {
        return ["event": "\(event)"]
    }
}
