//
//  IssueDeliveryType.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

enum IssueDeliveryType {
    
    case office
    case courier
    
    var changeTypeActionText: String {
        switch self {
        case .office: return "Вызвать курьера"
        case .courier: return "Приду в офис самостоятельно"
        }
    }
    
    var hintText: String {
        switch self {
        case .office:
            // swiftlint:disable:next line_length
            return "Для подтверждения адреса вам нужно принести квитанцию ЖКХ не старше трёх месяцев в наш ближайший офис."
        case .courier:
            return "Дождитесь курьера по адресу {value} и сфотографируйте QR-код, который он принесёт."
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
        case .office: params["value"] = "Самовывоз"
        case .courier: params["value"] = "Курьер"
        }
        
        return [params]
    }
    
    var deliveryComment: String {
        switch self {
        case .office: return "Cменился способ доставки. Клиент подойдет в офис."
        case .courier: return "Cменился способ доставки. Подготовить пакет для курьера."
        }
    }
    
}
