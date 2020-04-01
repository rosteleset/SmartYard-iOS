//
//  IssueDeliveryType.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit

enum IssueDeliveryType {
    
    case officeRequest
    case courierRequest
    
    var actionText: String {
        switch self {
        case .officeRequest:
            return "Вызвать курьера"
        case .courierRequest:
            return "Приду в офис самостоятельно"
        }
    }
    
    var hintText: String {
        switch self {
        case .officeRequest:
            // swiftlint:disable:next line_length
            return "Для подтверждения адреса вам нужно принести квитанцию ЖКХ не старше трёх месяцев в ближайший офис Lanta."
        case .courierRequest:
            return "Дождитесь курьера по адресу {value} и сфотографируйте QR-код, который он принесёт."
        }
    }
    
    var image: UIImage? {
        let name: String
        
        switch self {
        case .officeRequest: name = "Woman"
        case .courierRequest: name = "Man"
        }
        
        return UIImage(named: name)
    }
    
    var deliveryCustomFields: [String: String] {
        var params: [String: String] = ["number": "10941"]
        
        switch self {
        case .officeRequest:
            params["value"] = "Самовывоз"
        case .courierRequest:
            params["value"] = "Курьер"
        }
        
        return params
    }
    
    var deliveryComment: String {
        switch self {
        case .officeRequest:
            return "Cменился способ доставки. Клиент подойдет в офис."
        case .courierRequest:
            return "Cменился способ доставки. Подготовить пакет для курьера."
        }
    }
    
}
