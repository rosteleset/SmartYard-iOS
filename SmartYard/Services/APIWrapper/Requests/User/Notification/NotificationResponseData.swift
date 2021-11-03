//
//  NotificationResponseData.swift
//  SmartYard
//
//  Created by admin on 30/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct NotificationResponseData: Decodable {
    
    let money: Bool
    let enable: Bool
    
    private enum CodingKeys: String, CodingKey {
        case money
        case enable
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let moneyRawValue = try container.decode(String.self, forKey: .money)
        
        switch moneyRawValue {
        case "t": money = true
        case "f": money = false
        default: throw NSError.APIWrapperError.noDataError
        }
        
        let enableRawValue = try container.decode(String.self, forKey: .enable)
        
        switch enableRawValue {
        case "t": enable = true
        case "f": enable = false
        default: throw NSError.APIWrapperError.noDataError
        }
    }
    
}
