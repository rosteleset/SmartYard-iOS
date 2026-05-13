//
//  AnalyticsScreenTracking+Screens.swift
//  SmartYard
//
//  Created by Александр Попов on 13.05.2026.
//

import Foundation

extension MainMenuViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "main" }
    var analyticsScreenSource: String? { "tab_bar" }
}

extension InputPhoneNumberViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "auth" }
    var analyticsScreenSource: String? { "app_start" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.authScreenOpened(source: analyticsScreenSource)]
    }
}

extension PinCodeViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "auth" }
    var analyticsScreenSource: String? { "auth_flow" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.authScreenOpened(source: analyticsScreenSource)]
    }
}

extension OutgoingCallViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "auth" }
    var analyticsScreenSource: String? { "auth_flow" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.authScreenOpened(source: analyticsScreenSource)]
    }
}

extension AuthByContractNumViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "auth" }
    var analyticsScreenSource: String? { "auth_flow" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.authScreenOpened(source: analyticsScreenSource)]
    }
}

extension SelectProviderViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "auth" }
    var analyticsScreenSource: String? { "auth_flow" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.authScreenOpened(source: analyticsScreenSource)]
    }
}

extension UserNameViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "profile" }
    var analyticsScreenSource: String? { "auth_flow" }
}

extension SettingsViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "settings" }
    var analyticsScreenSource: String? { "tab_bar" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.settingsOpened(source: analyticsScreenSource)]
    }
}

extension CommonSettingsViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "notifications_settings" }
    var analyticsScreenSource: String? { "settings" }
}

extension AddressesListViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "addresses" }
    var analyticsScreenSource: String? { "tab_bar" }
}

extension AddressAccessViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "intercom" }
    var analyticsScreenSource: String? { "settings" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.intercomScreenOpened(source: analyticsScreenSource)]
    }
}

extension DetailGateAccessViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "intercom" }
    var analyticsScreenSource: String? { "intercom" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.intercomScreenOpened(source: analyticsScreenSource)]
    }
}

extension CamerasListViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "cameras_list" }
    var analyticsScreenSource: String? { "addresses" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.camerasListOpened(source: analyticsScreenSource)]
    }
}

extension YardMapViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "cameras_list" }
    var analyticsScreenSource: String? { "map" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.camerasListOpened(source: analyticsScreenSource)]
    }
}

extension SelectCameraContainerViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "camera_details" }
    var analyticsScreenSource: String? { "cameras_list" }
}

extension OnlinePageViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "camera_details" }
    var analyticsScreenSource: String? { "live_stream" }
}

extension ArchivePageViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "camera_details" }
    var analyticsScreenSource: String? { "archive" }
}

extension PlayArchiveVideoViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "event_details" }
    var analyticsScreenSource: String? { "archive" }
}

extension OnlineFullscreenViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "camera_details" }
    var analyticsScreenSource: String? { "fullscreen" }
}

extension HistoryViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "events_list" }
    var analyticsScreenSource: String? { "addresses" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.eventsListOpened(source: analyticsScreenSource)]
    }
}

extension HistoryDetailViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "event_details" }
    var analyticsScreenSource: String? { "events_list" }
}

extension PaymentsViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "payments" }
    var analyticsScreenSource: String? { "tab_bar" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.paymentsScreenOpened(source: analyticsScreenSource)]
    }
}

extension PayContractViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "payments" }
    var analyticsScreenSource: String? { "payments" }
}

extension PaymentPopupController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "payments" }
    var analyticsScreenSource: String? { "payment_popup" }
}

extension QRCodeScanViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "qr_scanner" }
    var analyticsScreenSource: String? { "addresses" }
    var analyticsAdditionalScreenEvents: [AnalyticsEvent] {
        [AppAnalyticsEvent.qrScannerOpened(source: analyticsScreenSource)]
    }
}

extension NotificationsViewController: AnalyticsScreenTrackable {
    var analyticsScreenName: String { "notifications" }
    var analyticsScreenSource: String? { "tab_bar" }
}
