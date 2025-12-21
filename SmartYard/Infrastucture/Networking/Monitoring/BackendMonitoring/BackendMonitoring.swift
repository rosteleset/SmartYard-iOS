//
//  BackendMonitoring.swift
//  SmartYard
//
//  Created by Александр Попов on 19.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxSwift

protocol BackendMonitoring {
    var currentStatus: BackendStatus { get }
    var status: Observable<BackendStatus> { get }

    func setEnabled(_ enabled: Bool)
    func updateHealthURL(_ url: URL?)

    func reportUnavailable()          // ретраер/слой сети сигналит: «наш API недоступен»
    func reportMaybeAvailable()       // сигнал: «похоже, оживает», триггерим /health-проверку
}

enum BackendStatus: Equatable { case available, unavailable, unknown }
