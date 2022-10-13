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
    let paymentsUrl: String?
    let supportPhone: String?
    
    var dictionary: [AnyHashable: Any] {
        var result: [AnyHashable: Any] = [:]
        
        if let cityCams = cityCams {
            result["cityCams"] = cityCams
        }
        if let payments = payments {
            result["payments"] = payments
        }
        if let paymentsUrl = paymentsUrl {
            result["paymentsUrl"] = paymentsUrl
        }
        if let supportPhone = supportPhone {
            result["supportPhone"] = supportPhone
        }
        return result
    }
    
    private enum CodingKeys: String, CodingKey {
        case paymentsUrl
        case cityCams
        case payments
        case supportPhone
    }
    
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
        
        paymentsUrl = try? container.decode(String.self, forKey: .paymentsUrl)
        supportPhone = try? container.decode(String.self, forKey: .supportPhone)
    }
    
    init() {
        cityCams = nil
        payments = nil
        paymentsUrl = nil
        supportPhone = nil
    }
}
