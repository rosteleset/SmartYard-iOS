//
//  NetworkMonitor.swift
//  SmartYard
//
//  Created by Александр Попов on 17.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Foundation
import Network
import Alamofire
import RxSwift
import RxCocoa

final class InternetMonitor: InternetMonitoring {
    var currentStatus: InternetStatus { statusRelay.value }
    var status: Observable<InternetStatus> { statusRelay.asObservable() }

    private lazy var statusRelay = BehaviorRelay<InternetStatus>(
        value: monitor.currentPath.status == .satisfied ? .online : .offline
    )

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "InternetMonitor")

    init() { start() }

    deinit { monitor.cancel() }

    private func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.handle(path: path) }
        }
        monitor.start(queue: queue)
    }

    private func handle(path: NWPath) {
        let new: InternetStatus = (path.status == .satisfied) ? .online : .offline
        update(new)
    }

    private func update(_ new: InternetStatus) {
        guard statusRelay.value != new else { return }
        statusRelay.accept(new)
    }
}

