//
//  PayTypeObject.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 08.07.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

enum PaymentSystem: String {
    case SBP
    case NEW
    case MASTERCARD
    case VISA
    case MIR
    case OTHER
    
    var label: String {
        switch self {
        case .SBP:
            return "Система быстрых платежей"
        default:
            return self.rawValue + " *"
        }
    }
    
    var labelSelectedColor: UIColor {
        return UIColor.SmartYard.textAddon
    }
    
    var borderSelectedColor: UIColor {
        return UIColor.SmartYard.blue
    }
    
    var borderUnselectedColor: UIColor {
        return .clear
    }
    
    var iconSelected: UIImage? {
        guard let image = UIImage(named: "Pay" + self.rawValue) else {
            return nil
        }
        return image
    }
}

struct PayTypeObject: Equatable {
    let number: Int
    let bindingId: String?
    let paymentWay: PaymentWays
    let paymentSystem: PaymentSystem
    let label: String
    let isCardActions: Bool
    
    var isSelected: Bool
}
