//
//  APICard.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 01.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import UIKit

enum PaymentWays: String {
    case CARD
    case SBP
    case NEW
}

struct APICard: Decodable {

    let bindingId: String
    let maskedPan: String
    let paymentWay: PaymentWays?
    let paymentSystem: PaymentSystem?
    let displayLabel: String?
    let autopay: Bool

    private enum CodingKeys: String, CodingKey {
        case bindingId
        case maskedPan
        case paymentWay
        case paymentSystem
        case displayLabel
        case autopay
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        bindingId = try container.decode(String.self, forKey: .bindingId)
        maskedPan = try container.decode(String.self, forKey: .maskedPan)
        
        if let paymentWayRawValue = try? container.decode(String.self, forKey: .paymentWay) {
            paymentWay = PaymentWays(rawValue: paymentWayRawValue)
        } else {
            paymentWay = nil
        }
        
        if let paymentSystemRawValue = try? container.decode(String.self, forKey: .paymentSystem) {
            paymentSystem = PaymentSystem(rawValue: paymentSystemRawValue.uppercased())
        } else {
            paymentSystem = nil
        }
        
        displayLabel = try? container.decode(String.self, forKey: .displayLabel)
        autopay = try container.decode(Bool.self, forKey: .autopay)
//        let isAutopayRawValue = (try? container.decode(String.self, forKey: .autopay)) ?? ""
//        
//        switch isAutopayRawValue {
//        case "t": autopay = true
//        default: autopay = false
//        }
    }
}
