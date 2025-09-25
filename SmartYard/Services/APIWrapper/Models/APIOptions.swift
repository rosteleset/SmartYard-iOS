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
    let validationPattern: NameValidationPattern?
    let deliveryTabsConfig: DeliveryTabsConfig?

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
        case validationNamePattern
        case validationPatronymicPattern
        case validationLastPattern
        case addressVerificationTabLayoutVisible
        case addressVerificationTab1Visible
        case addressVerificationTab2Visible
    }

    // swiftlint:disable:next cyclomatic_complexity
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        func boolFromTF(_ key: CodingKeys) -> Bool? {
            guard let raw = try? container.decode(String.self, forKey: key) else { return nil }
            switch raw {
            case "t": return true
            case "f": return false
            default: return nil
            }
        }

        cityCams = boolFromTF(.cityCams)
        payments = boolFromTF(.payments)
        chat = boolFromTF(.chat)

        if let guestRaw = try? container.decode(String.self, forKey: .guestAccess) {
            switch guestRaw {
            case "turnOnAndOff": guestAccessOnOnly = false
            case "turnOnOnly": guestAccessOnOnly = true
            default: guestAccessOnOnly = true
            }
        } else {
            guestAccessOnOnly = true
        }

        let namePattern: String? = try? container.decode(
            String.self,
            forKey: .validationNamePattern
        )
        let patronymicPattern: String? = try? container.decode(
            String.self,
            forKey: .validationPatronymicPattern
        )
        let lastPattern: String? = try? container.decode(
            String.self,
            forKey: .validationLastPattern
        )

        validationPattern = NameValidationPattern(
            validationNamePattern: namePattern,
            validationPatronymicPattern: patronymicPattern,
            validationLastPattern: lastPattern
        )

        deliveryTabsConfig = DeliveryTabsConfig(
            deliveryTabs: DeliveryTabs(
                layoutVisible: boolFromTF(.addressVerificationTabLayoutVisible),
                courierVisible: boolFromTF(.addressVerificationTab1Visible),
                officeVisible: boolFromTF(.addressVerificationTab2Visible)
            )
        )

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
        deliveryTabsConfig = nil
        validationPattern = nil
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

    enum TabNames: String, Decodable {
        case addresses
        case notifications
        case chat
        case pay
        case menu
    }

}

struct DeliveryTabs: Codable {
    let layoutVisible: Bool?
    let courierVisible: Bool?
    let officeVisible: Bool?
}

enum DeliveryTab: String, Codable, CaseIterable {
    case courier
    case office

    var title: String {
        switch self {
        case .courier: return NSLocalizedString("Via Courier", comment: "")
        case .office:  return NSLocalizedString("In Office", comment: "")
        }
    }
}

struct DeliveryTabsConfig: Codable, Equatable {
    let layoutVisible: Bool
    let visibleTabs: [DeliveryTab]

    init(deliveryTabs: DeliveryTabs) {
        var tabs: [DeliveryTab] = []
        if deliveryTabs.courierVisible == true { tabs.append(.courier) }
        if deliveryTabs.officeVisible == true { tabs.append(.office)  }

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
