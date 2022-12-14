//
//  APIExtension.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 LanTa. All rights reserved.
//

import Foundation
import UIKit

struct APIOptions: Decodable, EmptyDataInitializable {
    
    let cityCams: Bool?
    let payments: Bool?
    let chat: Bool?
    let chatOptions: ChatOptions?
    let paymentsUrl: String?
    let chatUrl: String?
    let supportPhone: String?
    
    private enum CodingKeys: String, CodingKey {
        case paymentsUrl
        case cityCams
        case payments
        case chat
        case chatOptions
        case chatUrl
        case supportPhone
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let cityCamsRaw = try? container.decode(String.self, forKey: .cityCams) {
            switch cityCamsRaw {
            case "t": cityCams = true
            case "f": cityCams = false
            default: cityCams = nil
            }
        } else {
            cityCams = nil
        }
        
        if let paymentsRaw = try? container.decode(String.self, forKey: .payments) {
            switch paymentsRaw {
            case "t": payments = true
            case "f": payments = false
            default: payments = nil
            }
        } else {
            payments = nil
        }
        
        if let chatRaw = try? container.decode(String.self, forKey: .chat) {
            switch chatRaw {
            case "t": chat = true
            case "f": chat = false
            default: chat = nil
            }
        } else {
            chat = nil
        }
        
        chatOptions = try? container.decode(ChatOptions.self, forKey: .chatOptions)
        paymentsUrl = try? container.decode(String.self, forKey: .paymentsUrl)
        chatUrl = try? container.decode(String.self, forKey: .chatUrl)
        supportPhone = try? container.decode(String.self, forKey: .supportPhone)
    }
    
    init() {
        cityCams = nil
        payments = nil
        paymentsUrl = nil
        chatUrl = nil
        supportPhone = nil
        chat = nil
        chatOptions = nil
    }
}

struct ChatOptions: Decodable {
    let id: String
    let domain: String
    let token: String
}
