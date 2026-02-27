//
//  QuickActionResolution.swift
//  SmartYard
//
//  Created by Александр Попов on 27.02.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//


enum QuickActionResolution {
    case target(QuickActionResolvedTarget)
    case unavailable(message: String)
}