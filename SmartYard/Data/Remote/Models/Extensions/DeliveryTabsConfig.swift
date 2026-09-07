//
//  DeliveryTabsConfig.swift
//  SmartYard
//
//  Created by Александр Попов.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Foundation

struct DeliveryTabs: Codable {
    let layoutVisible: Bool?
    let courierVisible: Bool?
    let officeVisible: Bool?
}

enum DeliveryTab: String, Codable, CaseIterable {
    case courier
    case office
}

struct DeliveryTabsConfig: Codable, Equatable {
    let layoutVisible: Bool
    let visibleTabs: [DeliveryTab]
}
