//
//  APIPaymentsListAccount.swift
//  SmartYard
//
//  Created by admin on 25/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation

struct APIPaymentsListAccount: Decodable {
    
    let clientId: String
    let contractName: String
    let contractPayName: String
    let isBlocked: Bool
    let balance: Double
    let bonus: Double
    let payAdvice: Double?
    let services: [String]
    let lcab: String?
    let lcabPay: String?
    
    var servicesAvailability: [SettingsServiceType: Bool] {
        return [
            .internet: services.contains("internet"),
            .iptv: services.contains("iptv"),
            .ctv: services.contains("ctv"),
            .phone: services.contains("phone"),
            .cctv: services.contains("cctv"),
            .domophone: services.contains("domophone"),
            .gsm: services.contains("gsm"),
            .barrier: services.contains("barrier")
        ]
    }
    
    private enum CodingKeys: String, CodingKey {
        case clientId
        case contractName
        case contractPayName
        case isBlocked = "blocked"
        case balance
        case bonus
        case payAdvice
        case services
        case lcab
        case lcabPay
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        clientId = try container.decode(String.self, forKey: .clientId)
        contractName = try container.decode(String.self, forKey: .contractName)
        contractPayName = try container.decode(String.self, forKey: .contractPayName)
        
        let isBlockedRawValue = try container.decode(String.self, forKey: .isBlocked)
        
        switch isBlockedRawValue {
        case "t": isBlocked = true
        case "f": isBlocked = false
        default: throw NSError.APIWrapperError.noDataError
        }
        
        balance = try container.decode(Double.self, forKey: .balance)
        bonus = try container.decode(Double.self, forKey: .bonus)
        payAdvice = try? container.decode(Double.self, forKey: .payAdvice)
        services = try container.decode([String].self, forKey: .services)
        
        lcab = try? container.decode(String.self, forKey: .lcab)
        lcabPay = try? container.decode(String.self, forKey: .lcabPay)
    }
    
}
