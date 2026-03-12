//
//  IssueDeliveryType.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

enum IssueDeliveryType: String, Codable {
    
    case office
    case courier
    
    var changeTypeActionText: String {
        switch self {
        case .office: return L10n.Address.Confirmation.Delivery.courierOption
        case .courier: return L10n.Address.Confirmation.Delivery.officeOption
        }
    }
    
    var hintText: String {
        switch self {
        case .office:
            // swiftlint:disable:next line_length
            return L10n.Address.Confirmation.Office.hint
        case .courier:
            return L10n.Address.Confirmation.Courier.hintFormat
        }
    }
    
    var image: UIImage? {
        let name: String
        
        switch self {
        case .office: name = "Woman"
        case .courier: name = "Man"
        }
        
        return UIImage(named: name)
    }
    
    var deliveryCustomFields: [[String: String]] {
        var params: [String: String] = ["number": "10941"]
        
        switch self {
        case .office: params["value"] = L10n.Address.Confirmation.Delivery.pickupTitle
        case .courier: params["value"] = L10n.Address.Confirmation.Delivery.courierTitle
        }
        
        return [params]
    }
    
    var deliveryComment: String {
        switch self {
        case .office: return L10n.Address.Confirmation.Delivery.officeChangeMessage
        case .courier: return L10n.Address.Confirmation.Delivery.courierChangeMessage
        }
    }
    
}
