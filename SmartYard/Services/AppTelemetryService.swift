//
//  AppTelemetryService.swift
//  SmartYard
//
//  Created by Александр Попов on 03.03.2026.
//

import FirebaseAnalytics
import FirebaseCrashlytics

protocol AppTelemetryServicing {
    func configureCrashlytics()
    func setCrashlyticsUserID(_ userID: String?)
    func setAnalyticsOperator(id: String, name: String)
    func log(_ message: String)
    func record(error: Error)
}

final class AppTelemetryService: AppTelemetryServicing {
    static let shared = AppTelemetryService()

    private let lock = NSLock()
    private var crashlyticsService: Crashlytics?

    private init() {}

    func configureCrashlytics() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.configureCrashlytics()
            }
            return
        }

        setCrashlyticsService(Crashlytics.crashlytics())
    }

    func setCrashlyticsUserID(_ userID: String?) {
        currentCrashlyticsService()?.setUserID(userID ?? "unknown")
    }

    func setAnalyticsOperator(id: String, name: String) {
        Analytics.setUserProperty(id, forName: "provider_id")
        Analytics.setUserProperty(name, forName: "provider_name")
    }

    func log(_ message: String) {
        currentCrashlyticsService()?.log(message)
    }

    func record(error: Error) {
        currentCrashlyticsService()?.record(error: error)
    }

    private func setCrashlyticsService(_ crashlyticsService: Crashlytics) {
        lock.lock()
        defer { lock.unlock() }

        self.crashlyticsService = crashlyticsService
    }

    private func currentCrashlyticsService() -> Crashlytics? {
        lock.lock()
        defer { lock.unlock() }

        return crashlyticsService
    }
}
