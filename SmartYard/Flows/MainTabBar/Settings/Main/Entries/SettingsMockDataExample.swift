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
    
    let internetState: SettingsServiceState
    let tvState: SettingsServiceState
    let phoneState: SettingsServiceState
    let lockState: SettingsServiceState
    let cameraState: SettingsServiceState
    
    static let firstExample: SettingsMockDataExample = {
        SettingsMockDataExample(
            clientId: "10000",
            address: "г. Тамбов, ул. Советская, 16, кв. 4",
            contractNumber: "68992",
            internetState: .activated,
            tvState: .notActivated,
            phoneState: .activated,
            lockState: .notActivated,
            cameraState: .unavailable
        )
    }()
    
    static let secondExample: SettingsMockDataExample = {
        SettingsMockDataExample(
            clientId: "20000",
            address: "г. Тамбов, ул. Мичуринская, 141А",
            contractNumber: "69325",
            internetState: .activated,
            tvState: .activated,
            phoneState: .activated,
            lockState: .activated,
            cameraState: .activated
        )
    }()
    
    static let thirdExample: SettingsMockDataExample = {
        SettingsMockDataExample(
            clientId: "30000",
            address: "г. Котовск, ул. Зимняя, 20",
            contractNumber: "69325",
            internetState: .unavailable,
            tvState: .unavailable,
            phoneState: .unavailable,
            lockState: .activated,
            cameraState: .activated
        )
    }()
    
}
