//
//  ConfirmCodeResponseData.swift
//  SmartYard
//
//  Created by admin on 03/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

enum RequestCodeResponseData: Decodable, EmptyDataInitializable {
    case otp
    case outgoingCall(confirmNumbers: [String])
    case flashCall
    
    init() {
        self = .otp
    }
    
    private enum CodingKeys: String, CodingKey {
        case method
        case confirmationNumbers
    }
    
    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        guard let container = container else {
            self = .otp
            return
        }
        
        let method = try? container.decode(String.self, forKey: .method)
        guard let method = method else {
            self = .otp
            return
        }
        
        switch method {
        case "outgoingCall":
            let confirmNumbers = try container.decode([String].self, forKey: .confirmationNumbers)
            self = .outgoingCall(confirmNumbers: confirmNumbers)
        case "flashCall":
            self = .flashCall
        default: self = .otp
        }
    }
}
