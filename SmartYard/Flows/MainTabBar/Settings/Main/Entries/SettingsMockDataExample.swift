//
//  SettingsMockDataExample.swift
//  SmartYard
//
//  Created by admin on 12/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct SettingsMockDataExample {
    
    let clientId: String
    
    let address: String
    let contractNumber: String
    
    let serviceStates: [SettingsServiceType: SettingsServiceState]
    
    static let firstExample: SettingsMockDataExample = {
        SettingsMockDataExample(
            clientId: "10000",
            address: "г. Тамбов, ул. Советская, 16, кв. 4",
            contractNumber: "68992",
            serviceStates: [
                .internet: .activated,
                .tv: .notActivated,
                .phone: .activated,
                .lock: .notActivated,
                .camera: .unavailable
            ]
        )
    }()
    
    static let secondExample: SettingsMockDataExample = {
        SettingsMockDataExample(
            clientId: "20000",
            address: "г. Тамбов, ул. Мичуринская, 141А",
            contractNumber: "69325",
            serviceStates: [
                .internet: .activated,
                .tv: .activated,
                .phone: .activated,
                .lock: .activated,
                .camera: .activated
            ]
        )
    }()
    
    static let thirdExample: SettingsMockDataExample = {
        SettingsMockDataExample(
            clientId: "30000",
            address: "г. Котовск, ул. Зимняя, 20",
            contractNumber: "69325",
            serviceStates: [
                .internet: .unavailable,
                .tv: .unavailable,
                .phone: .unavailable,
                .lock: .activated,
                .camera: .activated
            ]
        )
    }()
    
}
