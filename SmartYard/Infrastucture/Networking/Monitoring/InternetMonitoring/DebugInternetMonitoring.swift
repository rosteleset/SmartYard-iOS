//
//  DebugInternetMonitoring.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift

final class DebugInternetMonitoring: InternetMonitoring {
    private let base: InternetMonitoring
    private let debug: DebugNetworkController

    init(base: InternetMonitoring, debug: DebugNetworkController) {
        self.base = base
        self.debug = debug
    }

    var currentStatus: InternetStatus {
        switch debug.state.internet {
        case .auto: return base.currentStatus
        case .offline: return .offline
        case .online: return .online
        }
    }

    var status: Observable<InternetStatus> {
        Observable
            .combineLatest(
                base.status,
                debug.stateObservable
            )
            .map { baseStatus, debugState in
                switch debugState.internet {
                case .auto: return baseStatus
                case .offline: return .offline
                case .online: return .online
                }
            }
            .distinctUntilChanged()
    }
}
