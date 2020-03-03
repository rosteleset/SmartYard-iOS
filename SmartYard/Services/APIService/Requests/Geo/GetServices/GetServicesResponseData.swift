//
//  GetServicesResponseData.swift
//  SmartYard
//
//  Created by Mad Brains on 26.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

typealias GetServicesResponseData = [APIServiceModel]

extension GetServicesResponseData {
    
    func isServiceContains(service: SettingsServiceType) -> Bool {
        return contains { $0.icon == service.rawValue }
    }
    
}
