//
//  AnalyticsScreenTracking.swift
//  SmartYard
//
//  Created by Александр Попов on 13.05.2026.
//

protocol AnalyticsScreenTrackable: AnyObject {
    var analyticsScreenName: String { get }
    var analyticsScreenSource: String? { get }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] { get }
}

extension AnalyticsScreenTrackable {

    var analyticsScreenSource: String? { nil }

    var analyticsAdditionalScreenEvents: [AnalyticsEvent] { [] }
}

extension AnalyticsScreenTrackable {

    func trackAnalyticsScreenOpened() {
        AppAnalytics.log(
            AppAnalyticsEvent.screenOpened(
                screen: analyticsScreenName,
                source: analyticsScreenSource
            )
        )
        analyticsAdditionalScreenEvents.forEach(AppAnalytics.log)
    }
}
