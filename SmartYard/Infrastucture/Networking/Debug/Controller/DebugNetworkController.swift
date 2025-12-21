//
//  DebugNetworkController.swift
//  SmartYard
//
//  Created by Александр Попов on 18.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

final class DebugNetworkController {
    enum InternetOverride { case auto, offline, online }
    enum BackendOverride { case auto, unavailable, available }

    struct State: Equatable {
        var internet: InternetOverride = .auto
        var backend: BackendOverride = .auto
    }

    // MARK: - State

    private let stateRelay = BehaviorRelay<State>(value: State())

    var state: State { stateRelay.value }

    var stateObservable: Observable<State> {
        stateRelay
            .asObservable()
            .distinctUntilChanged()
    }

    // MARK: - Mutations

    func setInternet(_ value: InternetOverride) {
        update { $0.internet = value }
    }

    func setBackend(_ value: BackendOverride) {
        update { $0.backend = value }
    }

    func reset() {
        stateRelay.accept(State())
    }

    private func update(_ block: (inout State) -> Void) {
        var newState = stateRelay.value
        block(&newState)
        guard newState != stateRelay.value else { return }
        stateRelay.accept(newState)
    }
}
