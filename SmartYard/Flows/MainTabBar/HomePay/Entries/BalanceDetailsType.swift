//
//  BalanceDetailsType.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 13.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import UIKit

enum BalanceDetailsType: String {
    case charges
    case payments
    case accounts
    
    var icon: UIImage? {
        switch self {
        case .charges: return UIImage(named: "DetailDebpay")
        case .payments: return UIImage(named: "DetailAddpay")
        case .accounts: return UIImage(named: "DetailDebpay")
        }
    }
}
