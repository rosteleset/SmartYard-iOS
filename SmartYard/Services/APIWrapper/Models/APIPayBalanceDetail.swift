//
//  APIPayBalanceDetail.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 13.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation

struct APIPayBalanceDetail: Decodable {
    
    let type: BalanceDetailsType
    let title: String
    let date: Date
    let summa: Double
    
    private enum CodingKeys: String, CodingKey {
        case type
        case title
        case date
        case summa
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let typeRawValue = try container.decode(String.self, forKey: .type)
        type = try BalanceDetailsType(rawValue: typeRawValue).unwrapped(or: NSError.APIWrapperError.noDataError)
        
        title = try container.decode(String.self, forKey: .title)
        
        let dateRawValue = try container.decode(String.self, forKey: .date)
        date = try dateRawValue.dateFromAPIString.unwrapped(or: NSError.APIWrapperError.noDataError)
        
        summa = try container.decode(Double.self, forKey: .summa)
    }
}
