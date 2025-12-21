//
//  DebugBackendMonitoring.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift

final class DebugBackendMonitoring: BackendMonitoring {
    private let base: BackendMonitoring
    private let debug: DebugNetworkController

    init(base: BackendMonitoring, debug: DebugNetworkController) {
        self.base = base
        self.debug = debug
    }

    var currentStatus: BackendStatus {
        switch debug.state.backend {
        case .auto: return base.currentStatus
        case .unavailable: return .unavailable
        case .available: return .available
        }
    }

    var status: Observable<BackendStatus> {
        Observable
            .combineLatest(
                base.status,
                debug.stateObservable
            )
            .map { baseStatus, debugState in
                switch debugState.backend {
                case .auto: return baseStatus
                case .unavailable: return .unavailable
                case .available: return .available
                }
            }
            .distinctUntilChanged()
    }

    func setEnabled(_ enabled: Bool) { base.setEnabled(enabled) }
    func updateHealthURL(_ url: URL?) { base.updateHealthURL(url) }
    func reportUnavailable() { base.reportUnavailable() }
    func reportMaybeAvailable() { base.reportMaybeAvailable() }
}
