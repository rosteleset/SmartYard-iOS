//
//  PayRegisterResponseData.swift
//  SmartYard
//
//  Created by Александр Васильев on 14.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation

struct PayRegisterResponseData: Codable {
    
    let orderId: String
    let formUrl: String
}
