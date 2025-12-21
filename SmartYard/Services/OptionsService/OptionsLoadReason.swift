//
//  OptionsLoadReason.swift
//  SmartYard
//
//  Created by Александр Попов on 21.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

enum OptionsLoadReason: String {
    case coldStart
    case becameOnline
    case backendChanged
    case providerChanged
    case userPullToRefresh
}
