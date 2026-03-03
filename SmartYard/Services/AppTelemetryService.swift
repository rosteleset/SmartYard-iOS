//
//  AppTelemetryService.swift
//  SmartYard
//
//  Created by Александр Попов on 03.03.2026.
//

import FirebaseAnalytics
import FirebaseCrashlytics

protocol AppTelemetryServicing {
    func setCrashlyticsUserID(_ userID: String?)
    func setAnalyticsOperator(id: String, name: String)
    func log(_ message: String)
    func record(error: Error)
}

final class AppTelemetryService: AppTelemetryServicing {
    static let shared = AppTelemetryService()

    private init() {}

    func setCrashlyticsUserID(_ userID: String?) {
        Crashlytics.crashlytics().setUserID(userID ?? "unknown")
    }

    func setAnalyticsOperator(id: String, name: String) {
        Analytics.setUserProperty(id, forName: "provider_id")
        Analytics.setUserProperty(name, forName: "provider_name")
    }

    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    func record(error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}
