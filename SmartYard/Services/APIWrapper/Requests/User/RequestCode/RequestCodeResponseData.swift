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
    case pushMobile(requestId: String)
    
    init() {
        self = .otp
    }
    
    private enum CodingKeys: String, CodingKey {
        case method
        case confirmationNumbers
        case requestId
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
        case "push":
            let requestId = try container.decode(String.self, forKey: .requestId)
            self = .pushMobile(requestId: requestId)
        default: self = .otp
        }
    }
}
