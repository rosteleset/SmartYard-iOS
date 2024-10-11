//
//  GetCardsResponseData.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 03.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

enum CheckSendType: String, EmptyDataInitializable {
    case push
    case email
    
    init(rawValue: String) {
        if rawValue == "email" {
            self = .email
        } else {
            self = .push
        }
    }
    
    init() {
        self = .push
    }
}

struct GetCardsResponseData: Decodable {
    
    let payAdvice: Double?
    let merchant: Merchant
    let check: CheckSendType
    let email: String?
    let docLimit: String?
    let docTerms: String?
    let cards: [APICard]

    private enum CodingKeys: String, CodingKey {
        case payAdvice
        case merchant
        case check = "checkSendType"
        case email
        case docLimit = "document_limit"
        case docTerms = "document_service_terms"
        case cards
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        payAdvice = (try? container.decode(Double.self, forKey: .payAdvice)) ?? 0.00
        let merchantRawValue = try container.decode(String.self, forKey: .merchant)
        merchant = Merchant(rawValue: merchantRawValue)
        
        let checkRawValue = try container.decode(String.self, forKey: .check)
        check = CheckSendType(rawValue: checkRawValue)

        email = try? container.decode(String.self, forKey: .email)
        
        docLimit = try? container.decode(String.self, forKey: .docLimit)
        docTerms = try? container.decode(String.self, forKey: .docTerms)
        
        cards = (try? container.decode([APICard].self, forKey: .cards)) ?? []
    }
}
