//
//  SettingsControlPanelConfiguration.swift
//  SmartYard
//
//  Created by admin on 12/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

enum SettingsServiceState {
    
    case activated
    case notActivated
    case unavailable
    
}

struct SettingsControlPanelConfiguration: Hashable {
    
    let internetState: SettingsServiceState
    let tvState: SettingsServiceState
    let phoneState: SettingsServiceState
    let lockState: SettingsServiceState
    let cameraState: SettingsServiceState
    
}
