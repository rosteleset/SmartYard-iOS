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
        case .office: return NSLocalizedString("Call a courier", comment: "")
        case .courier: return NSLocalizedString("I'll come to the office myself", comment: "")
        }
    }
    
    var hintText: String {
        switch self {
        case .office:
            // swiftlint:disable:next line_length
            return NSLocalizedString("To confirm the address, you need to bring a utility bill no older than three months to our nearest office.", comment: "")
        case .courier:
            return NSLocalizedString("Wait for the courier at {value} and take a photo of the QR code he brings.", comment: "")
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
        case .office: params["value"] = NSLocalizedString("Pickup", comment: "")
        case .courier: params["value"] = NSLocalizedString("Courier", comment: "")
        }
        
        return [params]
    }
    
    var deliveryComment: String {
        switch self {
        case .office: return NSLocalizedString("The delivery method has changed. The client will come to the office.", comment: "")
        case .courier: return NSLocalizedString("The delivery method has changed. Prepare a package for the courier.", comment: "")
        }
    }
    
}
