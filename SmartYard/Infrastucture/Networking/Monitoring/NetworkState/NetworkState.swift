//
//  NetworkState.swift
//  SmartYard
//
//  Created by Александр Попов on 19.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

enum NetworkState: Equatable {
    case online
    case offline(reason: OfflineReason)

    enum OfflineReason: Equatable {
        case noInternet
        case backendUnavailable
    }
}
