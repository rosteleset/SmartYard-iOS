//
//  QuickActionResolution.swift
//  SmartYard
//
//  Created by Александр Попов on 27.02.2026.
//  Copyright © 2026 Sesameware. All rights reserved.
//


enum QuickActionResolution {
    case target(QuickActionResolvedTarget)
    case unavailable(message: String)
}