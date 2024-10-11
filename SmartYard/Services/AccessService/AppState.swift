//
//  AppState.swift
//  SmartYard
//
//  Created by admin on 18/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

enum AppState: Codable {
    
    case onboarding
    case phoneNumber
    case smsCode(phoneNumber: String)
    case authByOutgoingCall(phoneNumber: String, confirmPhoneNumber: String)
    case authByMobileProvider(phoneNumber: String, requestId: String)
    case userName
    case main
    
    private enum CodingKeys: String, CodingKey {
        case onboarding
        case phoneNumber
        case smsCode
        case outgoingCall
        case confirmPhoneNumber
        case requestId
        case userName
        case main
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if (try? values.decode(Bool.self, forKey: .onboarding)) != nil {
            self = .onboarding
            return
        }
        
        if (try? values.decode(Bool.self, forKey: .phoneNumber)) != nil {
            self = .phoneNumber
            return
        }
        
        if let confirmPhoneNumber = try? values.decode(String.self, forKey: .confirmPhoneNumber),
            let phoneNumber = try? values.decode(String.self, forKey: .outgoingCall) {
            self = .authByOutgoingCall(phoneNumber: phoneNumber, confirmPhoneNumber: confirmPhoneNumber)
            return
        }
        
        if let requestId = try? values.decode(String.self, forKey: .requestId),
           let phoneNumber = try? values.decode(String.self, forKey: .phoneNumber) {
            self = .authByMobileProvider(phoneNumber: phoneNumber, requestId: requestId)
        }
        
        if let phoneNumber = try? values.decode(String.self, forKey: .smsCode) {
            self = .smsCode(phoneNumber: phoneNumber)
            return
        }
        
        if (try? values.decode(Bool.self, forKey: .userName)) != nil {
            self = .userName
            return
        }
        
        if (try? values.decode(Bool.self, forKey: .main)) != nil {
            self = .main
            return
        }
        
        throw NSError.AccessServiceError.stateExtractionError
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .onboarding:
            try container.encode(true, forKey: .onboarding)
        case .phoneNumber:
            try container.encode(true, forKey: .phoneNumber)
        case .smsCode(let phoneNumber):
            try container.encode(phoneNumber, forKey: .smsCode)
        case let .authByOutgoingCall(phoneNumber, confirmNumber):
            try container.encode(phoneNumber, forKey: .outgoingCall)
            try container.encode(confirmNumber, forKey: .confirmPhoneNumber)
        case let .authByMobileProvider(phoneNumber, requestId):
            try container.encode(phoneNumber, forKey: .phoneNumber)
            try container.encode(requestId, forKey: .requestId)
        case .userName:
            try container.encode(true, forKey: .userName)
        case .main:
            try container.encode(true, forKey: .main)
        }
    }
    
}
