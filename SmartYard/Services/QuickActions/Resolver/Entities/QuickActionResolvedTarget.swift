//
//  QuickActionResolvedTarget.swift
//  SmartYard
//
//  Created by Александр Попов on 27.02.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

enum QuickActionResolvedTarget {
    case homeCamerasMap(houseId: String, address: String, cameras: [CameraObject]?)
    case homeCamerasList(houseId: String, address: String, tree: CamerasTree)
    case homeEvents(houseId: String, address: String)
    case menuAddressAccess(address: String, flatId: String, clientId: String?)
}
