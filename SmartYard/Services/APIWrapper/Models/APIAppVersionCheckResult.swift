//
//  APIAppVersionCheckResult.swift
//  SmartYard
//
//  Created by admin on 08.06.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

enum APIAppVersionCheckResult: String, Decodable, EmptyDataInitializable {
    
    case ok = "none"
    case upgrade = "upgrade"
    case forceUpgrade = "force_upgrade"
    
    init() {
        self = .ok
    }
    
}
