//
//  APIExtension.swift
//  SmartYard
//
//  Created by Александр Васильев on 15.03.2022.
//  Copyright © 2022 Sesameware. All rights reserved.
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
    let entrancesView: EntrancesViewType
    let activeTab: TabNames
    let issuesVersion: String?
    let lprsVersion: String?
    let validationPattern: NameValidationPattern?
    let deliveryTabsConfig: DeliveryTabsConfig?
    let eventsTracking: Bool?
    let stories: Bool?
    let stunUrl: String?

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
        case entrancesView
        case activeTab
        case issuesVersion
        case lprsVersion
        case validationNamePattern
        case validationPatronymicPattern
        case validationLastPattern
        case addressVerificationTabLayoutVisible
        case addressVerificationTab1Visible
        case addressVerificationTab2Visible
        case eventsTracking
        case stories
        case stunUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        cityCams = Self.decodeFlag(.cityCams, from: container)
        payments = Self.decodeFlag(.payments, from: container)
        chat = Self.decodeFlag(.chat, from: container)

        if let guestRaw = try? container.decode(String.self, forKey: .guestAccess) {
            switch guestRaw {
            case "turnOnAndOff": guestAccessOnOnly = false
            case "turnOnOnly": guestAccessOnOnly = true
            default: guestAccessOnOnly = true
            }
        } else {
            guestAccessOnOnly = true
        }

        validationPattern = NameValidationPattern(
            validationNamePattern: try? container.decode(String.self, forKey: .validationNamePattern),
            validationPatronymicPattern: try? container.decode(String.self, forKey: .validationPatronymicPattern),
            validationLastPattern: try? container.decode(String.self, forKey: .validationLastPattern)
        )

        deliveryTabsConfig = DeliveryTabsConfig(
            deliveryTabs: DeliveryTabs(
                layoutVisible: Self.decodeFlag(.addressVerificationTabLayoutVisible, from: container),
                courierVisible: Self.decodeFlag(.addressVerificationTab1Visible, from: container),
                officeVisible: Self.decodeFlag(.addressVerificationTab2Visible, from: container)
            )
        )

        chatOptions = try? container.decode(ChatOptions.self, forKey: .chatOptions)
        paymentsUrl = try? container.decode(String.self, forKey: .paymentsUrl)
        chatUrl = try? container.decode(String.self, forKey: .chatUrl)
        supportPhone = try? container.decode(String.self, forKey: .supportPhone)
        timeZone = try? container.decode(String.self, forKey: .timeZone)
        cctvView = (try? container.decode(CCTVViewType.self, forKey: .cctvView)) ?? .list
        entrancesView = (try? container.decode(EntrancesViewType.self, forKey: .entrancesView)) ?? .list
        activeTab = (try? container.decode(TabNames.self, forKey: .activeTab)) ?? .addresses
        issuesVersion = try? container.decode(String.self, forKey: .issuesVersion)
        if let version = try? container.decode(String.self, forKey: .lprsVersion) {
            lprsVersion = version
        } else {
            lprsVersion = (try? container.decode(Int.self, forKey: .lprsVersion)).map(String.init)
        }
        eventsTracking = Self.decodeFlag(.eventsTracking, from: container)
        stories = Self.decodeFlag(.stories, from: container)
        stunUrl = try? container.decode(String.self, forKey: .stunUrl)
    }

    private static func decodeFlag(_ key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) -> Bool? {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        guard let raw = try? container.decode(String.self, forKey: key) else { return nil }
        switch raw {
        case "t", "true": return true
        case "f", "false": return false
        default: return nil
        }
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
        entrancesView = .list
        activeTab = .addresses
        issuesVersion = nil
        lprsVersion = nil
        deliveryTabsConfig = nil
        validationPattern = nil
        eventsTracking = nil
        stories = nil
        stunUrl = nil
    }

    struct ChatOptions: Decodable {
        let id: String
        let domain: String
        let token: String
    }

    enum CCTVViewType: String, Decodable {
        case list
        case tree
        case userDefined
    }

    enum EntrancesViewType: String, Decodable {
        case list
        case preview
    }

    enum TabNames: String, Decodable {
        case addresses
        case notifications
        case chat
        case pay
        case menu
    }

}

extension DeliveryTab {
    var title: String {
        switch self {
        case .courier: return L10n.Address.Confirmation.Delivery.courierShort
        case .office:  return L10n.Address.Confirmation.Delivery.officeShort
        }
    }
}

extension DeliveryTabsConfig {
    init(deliveryTabs: DeliveryTabs) {
        var tabs: [DeliveryTab] = []
        if deliveryTabs.courierVisible == true { tabs.append(.courier) }
        if deliveryTabs.officeVisible == true { tabs.append(.office) }

        if tabs.isEmpty {
            Logger.logError("DeliveryTabsConfig: no tabs from server")
            // Поэтому по умолчанию делаем как было раньше, то есть показываем все табы
            tabs.append(.courier)
            tabs.append(.office)
        }

        self.layoutVisible = deliveryTabs.layoutVisible ?? (tabs.count > 1)
        self.visibleTabs = tabs
    }
}
