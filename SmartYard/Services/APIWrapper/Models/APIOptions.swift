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
    let guestAccessOnOnly: Bool
    let timeZone: String?
    let cctvView: CCTVViewType
    let activeTab: TabNames
    let issuesVersion: String?
    
    private enum CodingKeys: String, CodingKey {
        case paymentsUrl
        case cityCams
        case payments
        case chat
        case chatOptions
        case chatUrl
        case supportPhone
        case guestAccess
        case timeZone
        case cctvView
        case activeTab
        case issuesVersion
    }
    // swiftlint:disable:next cyclomatic_complexity
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
        
        if let guestAccessModeRaw = try? container.decode(String.self, forKey: .guestAccess) {
            switch guestAccessModeRaw {
            case "turnOnAndOff": guestAccessOnOnly = false
            case "turnOnOnly": guestAccessOnOnly = true
            default: guestAccessOnOnly = true
            }
        } else {
            guestAccessOnOnly = true
        }
        
        chatOptions = try? container.decode(ChatOptions.self, forKey: .chatOptions)
        paymentsUrl = try? container.decode(String.self, forKey: .paymentsUrl)
        chatUrl = try? container.decode(String.self, forKey: .chatUrl)
        supportPhone = try? container.decode(String.self, forKey: .supportPhone)
        timeZone = try? container.decode(String.self, forKey: .timeZone)
        cctvView = (try? container.decode(CCTVViewType.self, forKey: .cctvView)) ?? .list
        activeTab = (try? container.decode(TabNames.self, forKey: .activeTab)) ?? .addresses
        issuesVersion = try? container.decode(String.self, forKey: .issuesVersion)
    }
    
    init() {
        cityCams = nil
        payments = nil
        paymentsUrl = nil
        chatUrl = nil
        supportPhone = nil
        chat = nil
        chatOptions = nil
        guestAccessOnOnly = true
        timeZone = nil
        cctvView = .list
        activeTab = .addresses
        issuesVersion = nil
    }
    
    struct ChatOptions: Decodable {
        let id: String
        let domain: String
        let token: String
    }

    enum CCTVViewType: String, Decodable {
        case list
        case tree
    }
    
    enum TabNames: String, Decodable {
        case addresses
        case notifications
        case chat
        case pay
        case menu
    }
}

