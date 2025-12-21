//
//  NetworkEnviroment.swift
//  SmartYard
//
//  Created by Александр Попов on 17.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Alamofire

struct NetworkEnvironment {
    let internet: InternetMonitoring
    let backend: BackendMonitoring
    let session: Session
}

extension NetworkEnvironment {
    static func make(
        debug: DebugNetworkController
    ) -> NetworkEnvironment {
        let realInternet = InternetMonitor()
        let realBackend = BackendMonitor()

        let internet = DebugInternetMonitoring(
            base: realInternet,
            debug: debug
        )
        let backend = DebugBackendMonitoring(
            base: realBackend,
            debug: debug
        )

        let retrier = BaseRequestRetrier(
            internet: internet,
            backend: backend
        )

        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = false
        cfg.timeoutIntervalForRequest = 5
        cfg.timeoutIntervalForResource = 5

        let session = Session(configuration: cfg, interceptor: retrier)

        return NetworkEnvironment(
            internet: internet,
            backend: backend,
            session: session
        )
    }
}
