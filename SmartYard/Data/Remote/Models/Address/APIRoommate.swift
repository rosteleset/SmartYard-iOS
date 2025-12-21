//
//  APIRoommate.swift
//  SmartYard
//
//  Created by admin on 16/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

enum APIRoommateAccessType: String {
    
    case inner
    case outer
    case owner
    
}

struct APIRoommate: Decodable {
    
    let phone: String
    let expire: Date
    let type: APIRoommateAccessType
    
    private enum CodingKeys: String, CodingKey {
        case phone
        case expire
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        phone = try container.decode(String.self, forKey: .phone)
        
        let expireRawValue = try container.decode(String.self, forKey: .expire)
        expire = try expireRawValue.dateFromAPIString.unwrapped(or: NSError.APIWrapperError.noDataError)
        
        let typeRawValue = try container.decode(String.self, forKey: .type)
        type = try APIRoommateAccessType(rawValue: typeRawValue).unwrapped(or: NSError.APIWrapperError.noDataError)
    }
    
}
