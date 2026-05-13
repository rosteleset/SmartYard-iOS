//
//  AppAnalyticsEvent.swift
//  SmartYard
//
//  Created by Александр Попов on 13.05.2026.
//

// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
enum AppAnalyticsEvent {

    // MARK: App lifecycle

    static func appOpened(
        appVersion: String,
        buildNumber: String,
        environment: String
    ) -> AnalyticsEvent {
        event(
            "app_opened",
            appParameters(
                appVersion: appVersion,
                buildNumber: buildNumber,
                environment: environment
            )
        )
    }

    static func appFirstOpened(
        appVersion: String,
        buildNumber: String,
        environment: String
    ) -> AnalyticsEvent {
        event(
            "app_first_opened",
            appParameters(
                appVersion: appVersion,
                buildNumber: buildNumber,
                environment: environment
            )
        )
    }

    static func appBecameActive(
        appVersion: String,
        buildNumber: String,
        environment: String
    ) -> AnalyticsEvent {
        event(
            "app_became_active",
            appParameters(
                appVersion: appVersion,
                buildNumber: buildNumber,
                environment: environment
            )
        )
    }

    static func appEnteredBackground(
        appVersion: String,
        buildNumber: String,
        environment: String
    ) -> AnalyticsEvent {
        event(
            "app_entered_background",
            appParameters(
                appVersion: appVersion,
                buildNumber: buildNumber,
                environment: environment
            )
        )
    }

    // MARK: Shared

    static func screenOpened(screen: String, source: String?) -> AnalyticsEvent {
        event(
            "screen_opened",
            [
                "screen": screen,
                "source": source
            ]
        )
    }

    static func buttonTapped(screen: String, button: String) -> AnalyticsEvent {
        event(
            "button_tapped",
            [
                "screen": screen,
                "button": button
            ]
        )
    }

    static func appError(
        scenario: String,
        screen: String,
        errorCode: String?,
        safeMessage: String?
    ) -> AnalyticsEvent {
        event(
            "app_error",
            [
                "scenario": scenario,
                "screen": screen,
                "error_code": errorCode,
                "error_message_safe": AnalyticsSanitizer.safeMessage(safeMessage)
            ]
        )
    }

    // MARK: Auth

    static func authScreenOpened(source: String?) -> AnalyticsEvent {
        event(
            "auth_screen_opened",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth"
            ]
        )
    }

    static func authPhoneEntered(source: String?) -> AnalyticsEvent {
        event(
            "auth_phone_entered",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth"
            ]
        )
    }

    static func authCodeRequested(source: String?) -> AnalyticsEvent {
        event(
            "auth_code_requested",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth"
            ]
        )
    }

    static func authCodeRequestSuccess(source: String?) -> AnalyticsEvent {
        event(
            "auth_code_request_success",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth",
                "result": AnalyticsValue.success
            ]
        )
    }

    static func authCodeRequestFailed(
        source: String?,
        errorCode: String?,
        safeMessage: String?
    ) -> AnalyticsEvent {
        event(
            "auth_code_request_failed",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth",
                "result": AnalyticsValue.failed,
                "error_code": errorCode,
                "error_message_safe": AnalyticsSanitizer.safeMessage(safeMessage)
            ]
        )
    }

    static func authCodeConfirmed(source: String?) -> AnalyticsEvent {
        event(
            "auth_code_confirmed",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth",
                "result": AnalyticsValue.success
            ]
        )
    }

    static func authCodeConfirmationFailed(
        source: String?,
        errorCode: String?,
        safeMessage: String?
    ) -> AnalyticsEvent {
        event(
            "auth_code_confirmation_failed",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth",
                "result": AnalyticsValue.failed,
                "error_code": errorCode,
                "error_message_safe": AnalyticsSanitizer.safeMessage(safeMessage)
            ]
        )
    }

    static func authSuccess(source: String?) -> AnalyticsEvent {
        event(
            "auth_success",
            [
                "screen": "auth",
                "source": source,
                "scenario": "auth",
                "result": AnalyticsValue.success
            ]
        )
    }

    static func authLogout(source: String?) -> AnalyticsEvent {
        event(
            "auth_logout",
            [
                "screen": "settings",
                "source": source,
                "scenario": "auth"
            ]
        )
    }

    // MARK: Addresses

    static func addressListOpened(
        addressesCount: Int?,
        hasMultipleAddresses: Bool?,
        source: String?
    ) -> AnalyticsEvent {
        event(
            "address_list_opened",
            [
                "screen": "addresses",
                "addresses_count": addressesCount,
                "has_multiple_addresses": hasMultipleAddresses,
                "source": source
            ]
        )
    }

    static func addressSelected(
        addressesCount: Int?,
        hasMultipleAddresses: Bool?,
        source: String?
    ) -> AnalyticsEvent {
        event(
            "address_selected",
            [
                "screen": "addresses",
                "addresses_count": addressesCount,
                "has_multiple_addresses": hasMultipleAddresses,
                "source": source
            ]
        )
    }

    static func addressSwitchSuccess(
        addressesCount: Int?,
        hasMultipleAddresses: Bool?,
        source: String?
    ) -> AnalyticsEvent {
        event(
            "address_switch_success",
            [
                "screen": "addresses",
                "addresses_count": addressesCount,
                "has_multiple_addresses": hasMultipleAddresses,
                "source": source,
                "result": AnalyticsValue.success
            ]
        )
    }

    static func addressSwitchFailed(
        addressesCount: Int?,
        hasMultipleAddresses: Bool?,
        source: String?,
        errorCode: String?
    ) -> AnalyticsEvent {
        event(
            "address_switch_failed",
            [
                "screen": "addresses",
                "addresses_count": addressesCount,
                "has_multiple_addresses": hasMultipleAddresses,
                "source": source,
                "result": AnalyticsValue.failed,
                "error_code": errorCode
            ]
        )
    }

    // MARK: Door

    static func intercomScreenOpened(source: String?) -> AnalyticsEvent {
        event(
            "intercom_screen_opened",
            [
                "screen": "intercom",
                "source": source
            ]
        )
    }

    static func doorOpenTapped(
        screen: String,
        source: String?,
        accessType: String
    ) -> AnalyticsEvent {
        event(
            "door_open_tapped",
            [
                "screen": screen,
                "source": source,
                "scenario": "door_open",
                "access_type": accessType
            ]
        )
    }

    static func doorOpenSuccess(
        screen: String,
        source: String?,
        accessType: String
    ) -> AnalyticsEvent {
        event(
            "door_open_success",
            [
                "screen": screen,
                "source": source,
                "scenario": "door_open",
                "access_type": accessType,
                "result": AnalyticsValue.success
            ]
        )
    }

    static func doorOpenFailed(
        screen: String,
        source: String?,
        accessType: String,
        errorCode: String?
    ) -> AnalyticsEvent {
        event(
            "door_open_failed",
            [
                "screen": screen,
                "source": source,
                "scenario": "door_open",
                "access_type": accessType,
                "result": AnalyticsValue.failed,
                "error_code": errorCode
            ]
        )
    }

    static func doorOpenCancelled(
        screen: String,
        source: String?,
        accessType: String
    ) -> AnalyticsEvent {
        event(
            "door_open_cancelled",
            [
                "screen": screen,
                "source": source,
                "scenario": "door_open",
                "access_type": accessType,
                "result": AnalyticsValue.cancelled
            ]
        )
    }

    // MARK: Cameras

    static func camerasListOpened(source: String?) -> AnalyticsEvent {
        event(
            "cameras_list_opened",
            [
                "screen": "cameras_list",
                "source": source
            ]
        )
    }

    static func cameraSelected(
        screen: String,
        source: String?,
        cameraType: String
    ) -> AnalyticsEvent {
        event(
            "camera_selected",
            [
                "screen": screen,
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType
            ]
        )
    }

    static func cameraStreamStartRequested(
        screen: String,
        source: String?,
        cameraType: String,
        streamType: String
    ) -> AnalyticsEvent {
        event(
            "camera_stream_start_requested",
            [
                "screen": screen,
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType,
                "stream_type": streamType
            ]
        )
    }

    static func cameraStreamStarted(
        screen: String,
        source: String?,
        cameraType: String,
        streamType: String
    ) -> AnalyticsEvent {
        event(
            "camera_stream_started",
            [
                "screen": screen,
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType,
                "stream_type": streamType,
                "result": AnalyticsValue.success
            ]
        )
    }

    static func cameraStreamFailed(
        screen: String,
        source: String?,
        cameraType: String,
        streamType: String,
        errorCode: String?
    ) -> AnalyticsEvent {
        event(
            "camera_stream_failed",
            [
                "screen": screen,
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType,
                "stream_type": streamType,
                "result": AnalyticsValue.failed,
                "error_code": errorCode
            ]
        )
    }

    static func cameraFullscreenOpened(
        source: String?,
        cameraType: String,
        streamType: String
    ) -> AnalyticsEvent {
        event(
            "camera_fullscreen_opened",
            [
                "screen": "camera_details",
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType,
                "stream_type": streamType
            ]
        )
    }

    static func cameraFullscreenClosed(
        source: String?,
        cameraType: String,
        streamType: String
    ) -> AnalyticsEvent {
        event(
            "camera_fullscreen_closed",
            [
                "screen": "camera_details",
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType,
                "stream_type": streamType
            ]
        )
    }

    static func cameraLandscapeEnabled(source: String?, cameraType: String) -> AnalyticsEvent {
        event(
            "camera_landscape_enabled",
            [
                "screen": "camera_details",
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType
            ]
        )
    }

    static func cameraSnapshotTapped(
        screen: String,
        source: String?,
        cameraType: String,
        streamType: String
    ) -> AnalyticsEvent {
        event(
            "camera_snapshot_tapped",
            [
                "screen": screen,
                "source": source,
                "scenario": "camera",
                "camera_type": cameraType,
                "stream_type": streamType
            ]
        )
    }

    // MARK: Events history

    static func eventsListOpened(source: String?) -> AnalyticsEvent {
        event(
            "events_list_opened",
            [
                "screen": "events_list",
                "source": source
            ]
        )
    }

    static func eventDetailsOpened(
        eventType: String?,
        source: String?,
        hasMedia: Bool?
    ) -> AnalyticsEvent {
        event(
            "event_details_opened",
            [
                "screen": "event_details",
                "event_type": eventType,
                "source": source,
                "has_media": hasMedia
            ]
        )
    }

    static func eventFilterOpened(filterType: String, source: String?) -> AnalyticsEvent {
        event(
            "event_filter_opened",
            [
                "screen": "events_list",
                "filter_type": filterType,
                "source": source
            ]
        )
    }

    static func eventFilterApplied(filterType: String, source: String?) -> AnalyticsEvent {
        event(
            "event_filter_applied",
            [
                "screen": "events_list",
                "filter_type": filterType,
                "source": source
            ]
        )
    }

    static func eventTypeSelected(eventType: String, source: String?) -> AnalyticsEvent {
        event(
            "event_type_selected",
            [
                "screen": "events_list",
                "event_type": eventType,
                "source": source
            ]
        )
    }

    static func eventVideoOpened(eventType: String?, source: String?) -> AnalyticsEvent {
        event(
            "event_video_opened",
            [
                "screen": "event_details",
                "event_type": eventType,
                "source": source,
                "has_media": true
            ]
        )
    }

    static func eventImageOpened(eventType: String?, source: String?) -> AnalyticsEvent {
        event(
            "event_image_opened",
            [
                "screen": "event_details",
                "event_type": eventType,
                "source": source,
                "has_media": true
            ]
        )
    }

    // MARK: QR

    static func qrScannerOpened(source: String?) -> AnalyticsEvent {
        event(
            "qr_scanner_opened",
            [
                "screen": "qr_scanner",
                "source": source,
                "scenario": "qr_scan"
            ]
        )
    }

    static func qrScanStarted(source: String?) -> AnalyticsEvent {
        event(
            "qr_scan_started",
            [
                "screen": "qr_scanner",
                "source": source,
                "scenario": "qr_scan"
            ]
        )
    }

    static func qrScanSuccess(qrType: String, source: String?) -> AnalyticsEvent {
        event(
            "qr_scan_success",
            [
                "screen": "qr_scanner",
                "source": source,
                "scenario": "qr_scan",
                "qr_type": qrType,
                "result": AnalyticsValue.success
            ]
        )
    }

    static func qrScanFailed(
        qrType: String,
        source: String?,
        errorCode: String?
    ) -> AnalyticsEvent {
        event(
            "qr_scan_failed",
            [
                "screen": "qr_scanner",
                "source": source,
                "scenario": "qr_scan",
                "qr_type": qrType,
                "result": AnalyticsValue.failed,
                "error_code": errorCode
            ]
        )
    }

    static func qrScanInvalidFormat(qrType: String, source: String?) -> AnalyticsEvent {
        event(
            "qr_scan_invalid_format",
            [
                "screen": "qr_scanner",
                "source": source,
                "scenario": "qr_scan",
                "qr_type": qrType,
                "result": AnalyticsValue.failed,
                "error_code": "invalid_format"
            ]
        )
    }

    static func qrAccessGrantSuccess(qrType: String, source: String?) -> AnalyticsEvent {
        event(
            "qr_access_grant_success",
            [
                "screen": "qr_scanner",
                "source": source,
                "scenario": "qr_scan",
                "qr_type": qrType,
                "result": AnalyticsValue.success
            ]
        )
    }

    static func qrAccessGrantFailed(
        qrType: String,
        source: String?,
        errorCode: String?
    ) -> AnalyticsEvent {
        event(
            "qr_access_grant_failed",
            [
                "screen": "qr_scanner",
                "source": source,
                "scenario": "qr_scan",
                "qr_type": qrType,
                "result": AnalyticsValue.failed,
                "error_code": errorCode
            ]
        )
    }

    // MARK: Push

    static func pushPermissionRequested(source: String?) -> AnalyticsEvent {
        event(
            "push_permission_requested",
            [
                "source": source,
                "scenario": "push"
            ]
        )
    }

    static func pushPermissionGranted(source: String?) -> AnalyticsEvent {
        event(
            "push_permission_granted",
            [
                "source": source,
                "scenario": "push",
                "result": AnalyticsValue.success
            ]
        )
    }

    static func pushPermissionDenied(source: String?) -> AnalyticsEvent {
        event(
            "push_permission_denied",
            [
                "source": source,
                "scenario": "push",
                "result": AnalyticsValue.failed
            ]
        )
    }

    static func pushReceived(pushType: String, source: String?) -> AnalyticsEvent {
        event(
            "push_received",
            [
                "push_type": pushType,
                "source": source,
                "scenario": "push"
            ]
        )
    }

    static func pushOpened(pushType: String, source: String?) -> AnalyticsEvent {
        event(
            "push_opened",
            [
                "push_type": pushType,
                "source": source,
                "scenario": "push",
                "result": AnalyticsValue.success
            ]
        )
    }

    static func pushActionTapped(pushType: String, source: String?) -> AnalyticsEvent {
        event(
            "push_action_tapped",
            [
                "push_type": pushType,
                "source": source,
                "scenario": "push"
            ]
        )
    }

    static func pushOpenFailed(
        pushType: String,
        source: String?,
        errorCode: String?
    ) -> AnalyticsEvent {
        event(
            "push_open_failed",
            [
                "push_type": pushType,
                "source": source,
                "scenario": "push",
                "result": AnalyticsValue.failed,
                "error_code": errorCode
            ]
        )
    }

    // MARK: Payments

    static func paymentsScreenOpened(source: String?) -> AnalyticsEvent {
        event(
            "payments_screen_opened",
            [
                "screen": "payments",
                "source": source,
                "scenario": "payment"
            ]
        )
    }

    static func paymentStartTapped(
        paymentType: String,
        amountRange: String?,
        source: String?
    ) -> AnalyticsEvent {
        paymentEvent(
            "payment_start_tapped",
            paymentType: paymentType,
            amountRange: amountRange,
            result: nil,
            source: source,
            errorCode: nil
        )
    }

    static func paymentMethodSelected(
        paymentType: String,
        amountRange: String?,
        source: String?
    ) -> AnalyticsEvent {
        paymentEvent(
            "payment_method_selected",
            paymentType: paymentType,
            amountRange: amountRange,
            result: nil,
            source: source,
            errorCode: nil
        )
    }

    static func paymentStarted(
        paymentType: String,
        amountRange: String?,
        source: String?
    ) -> AnalyticsEvent {
        paymentEvent(
            "payment_started",
            paymentType: paymentType,
            amountRange: amountRange,
            result: nil,
            source: source,
            errorCode: nil
        )
    }

    static func paymentSuccess(
        paymentType: String,
        amountRange: String?,
        source: String?
    ) -> AnalyticsEvent {
        paymentEvent(
            "payment_success",
            paymentType: paymentType,
            amountRange: amountRange,
            result: AnalyticsValue.success,
            source: source,
            errorCode: nil
        )
    }

    static func paymentFailed(
        paymentType: String,
        amountRange: String?,
        source: String?,
        errorCode: String?
    ) -> AnalyticsEvent {
        paymentEvent(
            "payment_failed",
            paymentType: paymentType,
            amountRange: amountRange,
            result: AnalyticsValue.failed,
            source: source,
            errorCode: errorCode
        )
    }

    static func paymentCancelled(
        paymentType: String,
        amountRange: String?,
        source: String?
    ) -> AnalyticsEvent {
        paymentEvent(
            "payment_cancelled",
            paymentType: paymentType,
            amountRange: amountRange,
            result: AnalyticsValue.cancelled,
            source: source,
            errorCode: nil
        )
    }

    // MARK: Settings

    static func settingsOpened(source: String?) -> AnalyticsEvent {
        event(
            "settings_opened",
            [
                "screen": "settings",
                "source": source
            ]
        )
    }

    static func settingToggled(
        settingName: String,
        newValue: String,
        screen: String
    ) -> AnalyticsEvent {
        event(
            "setting_toggled",
            [
                "setting_name": settingName,
                "new_value": newValue,
                "screen": screen
            ]
        )
    }

    static func notificationSettingChanged(
        settingName: String,
        newValue: String,
        screen: String
    ) -> AnalyticsEvent {
        event(
            "notification_setting_changed",
            [
                "setting_name": settingName,
                "new_value": newValue,
                "screen": screen
            ]
        )
    }

    static func themeChanged(newValue: String, screen: String) -> AnalyticsEvent {
        event(
            "theme_changed",
            [
                "setting_name": "theme",
                "new_value": newValue,
                "screen": screen
            ]
        )
    }

    static func languageChanged(newValue: String, screen: String) -> AnalyticsEvent {
        event(
            "language_changed",
            [
                "setting_name": "language",
                "new_value": newValue,
                "screen": screen
            ]
        )
    }

    static func accountDeleteTapped(screen: String) -> AnalyticsEvent {
        event(
            "account_delete_tapped",
            [
                "screen": screen,
                "setting_name": "account_delete"
            ]
        )
    }

    static func logoutTapped(screen: String) -> AnalyticsEvent {
        event(
            "logout_tapped",
            [
                "screen": screen,
                "setting_name": "logout"
            ]
        )
    }

    // MARK: Private

    // swiftlint:disable:next function_parameter_count
    private static func paymentEvent(
        _ name: String,
        paymentType: String,
        amountRange: String?,
        result: String?,
        source: String?,
        errorCode: String?
    ) -> AnalyticsEvent {
        event(
            name,
            [
                "screen": "payments",
                "source": source,
                "scenario": "payment",
                "payment_type": paymentType,
                "amount_range": amountRange,
                "result": result,
                "error_code": errorCode
            ]
        )
    }

    private static func appParameters(
        appVersion: String,
        buildNumber: String,
        environment: String
    ) -> [String: Any?] {
        [
            "app_version": appVersion,
            "build_number": buildNumber,
            "environment": environment
        ]
    }

    private static func event(
        _ name: String,
        _ parameters: [String: Any?]
    ) -> AnalyticsEvent {
        AnalyticsEvent(
            name: name,
            parameters: parameters.compactMapValues { value in
                value
            }
        )
    }
}
