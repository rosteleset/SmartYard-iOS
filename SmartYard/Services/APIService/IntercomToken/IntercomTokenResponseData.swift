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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        let stateRawValue = try container.decode(String.self)
        let state = try TokenState(rawValue: stateRawValue).unwrapped(or: NSError.APIServiceError.mappingError)
        
        self.state = state
    }
    
}
