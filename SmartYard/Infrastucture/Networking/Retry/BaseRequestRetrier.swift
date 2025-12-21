//
//  BaseRequestRetrier.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Alamofire

final class BaseRequestRetrier: RequestInterceptor, @unchecked Sendable {
    struct Config {
        let maxRetries: Int
        let baseDelay: TimeInterval
        let maxDelay: TimeInterval
    }

    private let internet: InternetMonitoring
    private let backend: BackendMonitoring
    private let config: Config

    init(
        internet: InternetMonitoring,
        backend: BackendMonitoring,
        config: Config = .init(maxRetries: 2, baseDelay: 0.5, maxDelay: 1)
    ) {
        self.internet = internet
        self.backend = backend
        self.config = config
    }

    // MARK: Adapt
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest { urlRequest }

    // MARK: Retry
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // 1) Если интернета нет — ретраить бессмысленно
        guard internet.currentStatus == .online else {
            return completion(.doNotRetry)
        }

        // 2) Если это "no internet" (иногда прилетает как URLError),
        // то это не backend-ошибка — просто не ретраим/не трогаем backend.
        if isNotConnectedToInternet(error) {
            return completion(.doNotRetry)
        }

        // 3) Достигли лимита ретраев — считаем, что backend недоступен
        guard request.retryCount < config.maxRetries else {
            backend.reportUnavailable()
            return completion(.doNotRetry)
        }

        return completion(.retryWithDelay(nextDelay(for: request.retryCount)))
    }

    // MARK: Helpers

    private func nextDelay(for retryCount: Int) -> TimeInterval {
        let exp = min(config.maxRetries - 1, retryCount)
        let raw = min(config.maxDelay, config.baseDelay * pow(2.0, Double(exp)))
        // небольшой джиттер ±20%, чтобы не устраивать «тучи одновременно»
        let jitter = raw * Double.random(in: 0.8...1.2)
        return jitter
    }

    private func isNotConnectedToInternet(_ error: Error) -> Bool {
        if let urlError = error as? URLError,
           urlError.code == .notConnectedToInternet {
            return true
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain,
           nsError.code == URLError.notConnectedToInternet.rawValue {
            return true
        }

        if let afError = error as? AFError,
           let underlyingError = afError.underlyingError as? URLError,
           underlyingError.code == .notConnectedToInternet {
            return true
        }

        return false
    }
}
