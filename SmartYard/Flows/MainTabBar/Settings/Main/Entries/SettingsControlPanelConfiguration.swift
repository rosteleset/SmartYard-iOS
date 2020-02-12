//
//  SettingsControlPanelConfiguration.swift
//  SmartYard
//
//  Created by admin on 12/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

struct SettingsControlPanelConfiguration: Hashable {
    
    enum ServiceState {
        
        case activated
        case notActivated
        case unavailable
        
    }
    
    let internetState: ServiceState
    let tvState: ServiceState
    let phoneState: ServiceState
    let lockState: ServiceState
    let cameraState: ServiceState
    
}
