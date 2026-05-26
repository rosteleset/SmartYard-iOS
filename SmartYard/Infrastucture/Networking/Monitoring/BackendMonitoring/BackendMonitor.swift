//
//  BackendMonitor.swift
//  SmartYard
//
//  Created by Александр Попов on 17.10.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import Alamofire
import RxSwift
import RxRelay

final class BackendMonitor: BackendMonitoring {

    // MARK: - Config

    struct Config {
        /// Сколько подряд сетевых фейлов нужно, чтобы объявить backend unavailable,
        /// если мы ещё ни разу не видели успешных ответов в этой сессии.
        var failuresToDeclareUnavailableBeforeEverAvailable: Int = 2

        /// Сколько подряд сетевых фейлов нужно, чтобы объявить backend unavailable,
        /// если backend уже был available в этой сессии.
        var failuresToDeclareUnavailableAfterEverAvailable: Int = 2

        /// Сколько подряд успешных ответов нужно, чтобы вернуть available из unavailable.
        /// Обычно достаточно 1.
        var successesToDeclareAvailable: Int = 1

        /// После того как backend уже был доступен, не объявляем весь backend недоступным
        /// только из-за одного проблемного endpoint-а.
        var distinctFailurePathsToProbeAfterEverAvailable: Int = 2
    }

    // MARK: - Public

    private(set) var currentStatus: BackendStatus = .unknown {
        didSet { emitStatusIfNeeded(oldValue: oldValue, newValue: currentStatus, reason: lastReason) }
    }

    // MARK: - Private state

    private let queue = DispatchQueue(label: "BackendMonitor.queue")
    private var isEnabled: Bool = false

    private var healthURL: URL?

    private var hasEverBeenAvailableInSession: Bool = false

    private var consecutiveFailures: Int = 0
    private var consecutiveSuccesses: Int = 0
    private var consecutiveFailurePaths = Set<String>()
    private var isHealthCheckInFlight: Bool = false

    private var lastReason: String = ""

    private let statusSubject = PublishSubject<BackendStatus>()
    var status: Observable<BackendStatus> { statusSubject.asObservable() }

    private let config: Config

    // MARK: - Init

    init(config: Config = .init()) { self.config = config }

    // MARK: - API

    func updateHealthURL(_ url: URL?) {
        queue.async {
            guard self.healthURL != url else { return }
            self.healthURL = url
            self.lastReason = "healthURL updated"
            Logger.logDebug("BackendMonitor: healthURL=\(url?.absoluteString ?? "nil")")
        }
    }

    func setEnabled(_ enabled: Bool) {
        queue.async {
            guard self.isEnabled != enabled else { return }
            self.isEnabled = enabled
            self.lastReason = "setEnabled(\(enabled))"
            Logger.logDebug("BackendMonitor: enabled=\(enabled)")

            if !enabled {
                self.resetCounters()
                self.setStatus(.unknown, reason: "disabled")
            }
        }
    }

    /// Вызывать на ЛЮБОМ успешном реальном API ответе (2xx–3xx)
    func reportMaybeAvailable() {
        queue.async {
            guard self.isEnabled else {
                Logger.logDebug("reportMaybeAvailable() ignored (disabled)")
                return
            }

            self.consecutiveSuccesses += 1
            self.consecutiveFailures = 0
            self.consecutiveFailurePaths.removeAll()
            self.hasEverBeenAvailableInSession = true

            Logger.logDebug("reportMaybeAvailable() success=\(self.consecutiveSuccesses)")

            // Переход в available:
            if self.currentStatus != .available,
               self.consecutiveSuccesses >= self.config.successesToDeclareAvailable {
                self.setStatus(.available, reason: "real API success")
            }
        }
    }

    /// Вызывать на сетевых ошибках (timeout / cannotConnect / dns / connectionLost и т.д.)
    func reportUnavailable() {
        reportUnavailable(requestURL: nil)
    }

    /// Вызывать на сетевых ошибках (timeout / cannotConnect / dns / connectionLost и т.д.)
    func reportUnavailable(requestURL: URL?) {
        queue.async {
            guard self.isEnabled else {
                Logger.logDebug("reportUnavailable() ignored (disabled)")
                return
            }

            self.consecutiveFailures += 1
            self.consecutiveSuccesses = 0
            self.consecutiveFailurePaths.insert(self.failurePath(for: requestURL))

            let threshold = self.hasEverBeenAvailableInSession
            ? self.config.failuresToDeclareUnavailableAfterEverAvailable
            : self.config.failuresToDeclareUnavailableBeforeEverAvailable

            guard self.consecutiveFailures >= threshold else { return }

            if self.hasEverBeenAvailableInSession,
               self.consecutiveFailurePaths.count < self.config.distinctFailurePathsToProbeAfterEverAvailable {
                Logger.logDebug(
                    "BackendMonitor: keep available, failures=\(self.consecutiveFailures) paths=\(self.consecutiveFailurePaths.count)"
                )
                return
            }

            Logger.logDebug("BackendMonitor: failures=\(self.consecutiveFailures) threshold=\(threshold) paths=\(self.consecutiveFailurePaths.count) everAvailable=\(self.hasEverBeenAvailableInSession)")
            self.probeHealthBeforeDeclaringUnavailable(reason: "network failures reached threshold")
        }
    }

    // MARK: - Internals

    private func resetCounters() {
        consecutiveFailures = 0
        consecutiveSuccesses = 0
        consecutiveFailurePaths.removeAll()
        isHealthCheckInFlight = false
        hasEverBeenAvailableInSession = false
    }

    private func failurePath(for url: URL?) -> String {
        guard let url else { return "<unknown>" }
        return url.path.isEmpty ? "/" : url.path
    }

    private func setStatus(_ newStatus: BackendStatus, reason: String) {
        lastReason = reason
        if currentStatus == newStatus {
            Logger.logDebug("setStatus(\(newStatus)) skipped (same). reason=\(reason)")
            return
        }
        Logger.logDebug("STATUS \(currentStatus) -> \(newStatus). reason=\(reason)")
        currentStatus = newStatus
    }

    private func emitStatusIfNeeded(oldValue: BackendStatus, newValue: BackendStatus, reason: String) {
        guard oldValue != newValue else { return }
        statusSubject.onNext(newValue)
        Logger.logDebug("emit status=\(newValue) reason=\(reason)")
    }

    private func probeHealthBeforeDeclaringUnavailable(reason: String) {
        guard !isHealthCheckInFlight else {
            Logger.logDebug("BackendMonitor: health probe already in flight")
            return
        }

        guard let healthURL else {
            setStatus(.unavailable, reason: reason)
            return
        }

        isHealthCheckInFlight = true

        var request = URLRequest(url: healthURL, timeoutInterval: 8)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken = AccessService.shared.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = Data("{}".utf8)

        Logger.logDebug("BackendMonitor: health probe start url=\(healthURL.absoluteString)")

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            guard let self else { return }

            self.queue.async {
                self.isHealthCheckInFlight = false

                guard self.isEnabled else {
                    Logger.logDebug("BackendMonitor: health probe ignored (disabled)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse,
                   200...499 ~= httpResponse.statusCode {
                    self.consecutiveFailures = 0
                    self.consecutiveSuccesses += 1
                    self.hasEverBeenAvailableInSession = true
                    Logger.logDebug("BackendMonitor: health probe reachable status=\(httpResponse.statusCode)")

                    if self.currentStatus != .available,
                       self.consecutiveSuccesses >= self.config.successesToDeclareAvailable {
                        self.setStatus(.available, reason: "health probe reachable")
                    }
                    return
                }

                let errorDescription = error.map { ($0 as NSError).localizedDescription } ?? "status unavailable"
                Logger.logDebug("BackendMonitor: health probe failed \(errorDescription)")
                self.setStatus(.unavailable, reason: reason)
            }
        }.resume()
    }
}
