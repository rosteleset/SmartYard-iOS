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
        var isContains = false
        
        forEach { curService in
            if curService.icon == service.rawValue {
                isContains = true
            }
        }
        
        return isContains
    }
    
}
