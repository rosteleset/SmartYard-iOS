//
//  ConfirmCodeResponseData.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

struct ConfirmCodeResponseData: Decodable, EmptyDataInitializable {
    
    let accessToken: String
    let name: APIClientName?
    
    init() {
        accessToken = ""
        name = nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "accessToken"
        case name = "names"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        accessToken = try container.decode(String.self, forKey: .accessToken)
        name = try? container.decode(APIClientName.self, forKey: .name)
    }
    
}
