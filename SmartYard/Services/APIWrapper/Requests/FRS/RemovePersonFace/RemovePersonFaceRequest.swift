//
//  RemovePersonFacesRequest.swift
//  SmartYard
//
//  Created by Александр Васильев on 12.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct RemovePersonFaceRequest {
    let accessToken: String
    let flatId: Int
    let faceId: Int
}

extension RemovePersonFaceRequest {
    var requestParameters: [String: Any] {
        return ["flatId": "\(flatId)", "faceId": "\(faceId)"]
    }
}
