//
//  NetworkStateProvider.swift
//  SmartYard
//
//  Created by Александр Попов on 16.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift
import RxRelay

final class NetworkStateProvider: NetworkStateProviding, HasDisposeBag {
    private let internet: InternetMonitoring
    private let backend: BackendMonitoring
    private let relay: BehaviorRelay<NetworkState>

    var currentState: NetworkState { relay.value }
    var state: Observable<NetworkState> {
        relay.asObservable().distinctUntilChanged()
    }

    init(
        internet: InternetMonitoring,
        backend: BackendMonitoring
    ) {
        self.internet = internet
        self.backend = backend
        self.relay = BehaviorRelay(
            value: Self.makeState(
                internet: internet.currentStatus,
                backend: backend.currentStatus
            )
        )

        Observable
            .combineLatest(
                internet.status.startWith(internet.currentStatus),
                backend.status.startWith(backend.currentStatus)
            )
            .map(Self.makeState)
            .distinctUntilChanged()
            .bind(to: relay)
            .disposed(by: disposeBag)
    }

    private static func makeState(
        internet: InternetStatus,
        backend: BackendStatus
    ) -> NetworkState {

        if internet == .offline {
            return .offline(reason: .noInternet)
        }

        if backend == .unavailable {
            return .offline(reason: .backendUnavailable)
        }

        return .online
    }
}
