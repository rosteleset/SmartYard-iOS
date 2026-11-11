//
//  AdvancedSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import XCoordinator
import SmartYardSharedDataFramework
import WebKit
import FirebaseMessaging
import SkeletonView

final class CommonSettingsViewModel: BaseViewModel {
    
    let apiWrapper: APIWrapper
    let accessService: AccessService
    let pushNotificationService: PushNotificationService
    let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    let router: WeakRouter<SettingsRoute>
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<SettingsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
    }

    func bindAccountDeletion(_ input: Input, activityTracker: ActivityTracker, errorTracker: ErrorTracker) {
        input.deleteAccountTrigger
            .drive(
                onNext: { [weak self] in
                    self?.logAccountDeleteTapped()
                    let noAction = UIAlertAction(title: L10n.Common.no, style: .cancel, handler: nil)
                    
                    let yesAction = UIAlertAction(title: L10n.Common.yes, style: .destructive) { [weak self] _ in
                        guard let self = self else { return }
                        
                        self.apiWrapper.deleteAccount()
                            .subscribe(
                                onSuccess: { [weak self] _ in
                                    Logger.logDebug("Account deleted on backend")
                                    self?.pushNotificationService.resetInstanceId()
                                        .trackActivity(activityTracker)
                                        .trackError(errorTracker)
                                        .asDriver(onErrorJustReturn: nil)
                                        .ignoreNil()
                                        .drive(
                                            onNext: { [weak self] in
                                                SmartYardSharedDataUtilities.clearSharedData()
                                                self?.logAuthLogout(source: "account_delete")
                                                self?.accessService.logout()
                                            }
                                        )
                                        .disposed(by: self?.disposeBag ?? DisposeBag())
                                },
                                onFailure: { error in
                                    Logger.logDebug("Error delete account: \(error)")
                                }
                            )
                            .disposed(by: self.disposeBag)
                    }
                    
                    self?.router.trigger(
                        .dialog(
                            title: L10n.Settings.Common.DeleteAccount.title,
                            message: L10n.Settings.Common.DeleteAccount.message,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func bindLogout(_ input: Input, activityTracker: ActivityTracker, errorTracker: ErrorTracker) {
        input.logoutTrigger
            .drive(
                onNext: { [weak self] in
                    self?.logLogoutTapped()
                    let noAction = UIAlertAction(title: L10n.Common.no, style: .cancel, handler: nil)
                    
                    let yesAction = UIAlertAction(title: L10n.Common.yes, style: .destructive) { [weak self] _ in
                        guard let self = self else {
                            return
                        }

                        Messaging.messaging().isAutoInitEnabled = false
                        self.pushNotificationService.deletePushToken()
                        self.pushNotificationService.resetInstanceId()
                            .trackActivity(activityTracker)
                            .trackError(errorTracker)
                            .asDriver(onErrorJustReturn: nil)
                            .ignoreNil()
                                .drive(
                                    onNext: { [weak self] in
                                        SmartYardSharedDataUtilities.clearSharedData()
                                        self?.logAuthLogout(source: "settings")
                                        self?.accessService.logout()
                                    }
                                )
                            .disposed(by: self.disposeBag)
                    }
                    
                    self?.router.trigger(
                        .dialog(
                            title: L10n.Settings.Common.Logout.title,
                            message: L10n.Settings.Common.Logout.message,
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: - Показ Alert'а для выбора режима Appereance -
        // Обработаем здесь и SkeletonApereance так как он не предназначен для изменения appereance.
        // Мы будем строго указывать когда ему менять tint и gradient color!
    }
    
}

extension CommonSettingsViewModel {

    static func currentAppLanguageName() -> String {
        let localization = Bundle.main.preferredLocalizations.first ?? Locale.preferredLanguages.first ?? "ru"
        let languageCode = Locale(identifier: localization).languageCode ?? localization
        let languageName = Locale(identifier: languageCode)
            .localizedString(forLanguageCode: languageCode) ?? localization

        return languageName.prefix(1).uppercased() + String(languageName.dropFirst())
    }

    static func openApplicationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func logNotificationSettingChanged(_ settingName: String, isEnabled: Bool) {
        AppAnalytics.log(
            AppAnalyticsEvent.notificationSettingChanged(
                settingName: settingName,
                newValue: AnalyticsValue.bool(isEnabled),
                screen: "notifications_settings"
            )
        )
    }

    func logSettingToggled(
        _ settingName: String,
        isEnabled: Bool,
        screen: String
    ) {
        AppAnalytics.log(
            AppAnalyticsEvent.settingToggled(
                settingName: settingName,
                newValue: AnalyticsValue.bool(isEnabled),
                screen: screen
            )
        )
    }

    func logThemeChanged(_ value: String) {
        AppAnalytics.log(
            AppAnalyticsEvent.themeChanged(
                newValue: value,
                screen: "settings"
            )
        )
    }

    private func logLogoutTapped() {
        AppAnalytics.log(AppAnalyticsEvent.logoutTapped(screen: "settings"))
    }

    private func logAuthLogout(source: String) {
        AppAnalytics.log(AppAnalyticsEvent.authLogout(source: source))
    }

    private func logAccountDeleteTapped() {
        AppAnalytics.log(AppAnalyticsEvent.accountDeleteTapped(screen: "settings"))
    }

    func logAddressOrderReset() {
        AppAnalytics.log(
            AppAnalyticsEvent.settingToggled(
                settingName: "address_order_reset",
                newValue: "true",
                screen: "settings"
            )
        )
    }
}

extension CommonSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let editNameTrigger: Driver<Void>
        let showNotificationTrigger: Driver<Void>
        let moneyTrigger: Driver<Void>
        let callkitTrigger: Driver<Void>
        let speakerTrigger: Driver<Void>
        let showCamerasOnMapTrigger: Driver<Void>
        let languageTrigger: Driver<Void>
        let showApereanceApert: Driver<Void>
        let logoutTrigger: Driver<Void>
        let deleteAccountTrigger: Driver<Void>
        let callKitHintTrigger: Driver<Void>
        let addressOrderHintTrigger: Driver<Void>
        let addressOrderTrigger: Driver<Void>
    }
    
    struct Output {
        let name: Driver<String?>
        let phone: Driver<String?>
        let enableNotifications: Driver<Bool>
        let enableAccountBalanceWarning: Driver<Bool>
        let enableCallkit: Driver<Bool>
        let enableSpeakerByDefault: Driver<Bool>
        let showCamerasOnMap: Driver<Bool>
        let currentLanguage: Driver<String>
        let displaySettings: Driver<(Bool, Bool)>
        let appereanceButtonText: Driver<String>
        let isLoading: Driver<Bool>
        let shouldShowInitialLoading: Driver<Bool>
        let resetDidComplete: Driver<Void>
    }
    
}
