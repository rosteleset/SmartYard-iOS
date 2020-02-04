//
//  IntercomTokenResponseData.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import SwifterSwift

struct IntercomTokenResponseData: Decodable {
    
    let state: TokenState
    
    private enum CodingKeys: String, CodingKey {
        case state
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let stateRawValue = try container.decode(String.self, forKey: .state)
        let state = try TokenState(rawValue: stateRawValue).unwrapped(or: NSError.APIServiceError.mappingError)
        
        self.state = state
    }
    
}
