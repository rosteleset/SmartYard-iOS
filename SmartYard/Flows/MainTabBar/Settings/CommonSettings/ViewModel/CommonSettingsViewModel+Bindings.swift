// Created by Александр Попов. Copyright © 2026 Sesameware.

import UIKit
import RxCocoa
import RxSwift
import XCoordinator
import SmartYardSharedDataFramework
import WebKit
import FirebaseMessaging
import SkeletonView

extension CommonSettingsViewModel {
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()

        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }

                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: activityTracker,
                    errorTracker: errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(
                        .alert(
                            title: L10n.Common.error,
                            message: error.localizedDescription
                        )
                    )
                }
            )
            .disposed(by: disposeBag)

        // MARK: ActivityTracker для изначальной загрузки с показом скелетонов

        let initialLoadingTracker = ActivityTracker()

        // MARK: Загрузка изначального стейта

        let enableNotificationsSubject = BehaviorSubject<Bool>(value: false)
        let enableAccountBalanceWarningSubject = BehaviorSubject<Bool>(value: false)
        let enableCallkitSubject = BehaviorSubject<Bool>(value: accessService.prefersVoipForCalls)
        let enableSpeakerByDefaultSubject = BehaviorSubject<Bool>(value: accessService.prefersSpeakerForCalls)
        let showCamerasOnMapSubject = BehaviorSubject<Bool>(value: accessService.showList)
        let isChangeEnableListButtonVisible = accessService.cctvView == "userDefined"
        let isChangeAppearanceButtonVisible = Constants.isDarkModeEnabled
        let displaySettingsSubject = BehaviorSubject<(Bool, Bool)>(value: (isChangeEnableListButtonVisible, isChangeAppearanceButtonVisible))
        let appereanceButtonTextSubject = BehaviorSubject<String>(value: L10n.Settings.Common.Appearance.system)
        let currentLanguage = Driver.merge(
            .just(()),
            NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
                .map { _ in () }
                .asDriver(onErrorJustReturn: ())
        )
            .map { Self.currentAppLanguageName() }
        let resetConfirmed = PublishRelay<Void>()
        let resetDidComplete = resetConfirmed
            .do(onNext: { [weak self] in
                self?.accessService.userPreferredAddressOrder = []
            })

        ThemeManager.shared.currentTheme
            .subscribe(
                onNext: { style in
                    switch style {
                    case .unspecified:
                        appereanceButtonTextSubject.onNext(L10n.Settings.Common.Appearance.system)
                    case .light:
                        appereanceButtonTextSubject.onNext(L10n.Settings.Common.Appearance.light)
                    case .dark:
                        appereanceButtonTextSubject.onNext(L10n.Settings.Common.Appearance.dark)
                    @unknown default:
                        Logger.logWarning("!! Unknown UIUserInterfaceStyle encountered: \(style)")

                        appereanceButtonTextSubject.onNext(L10n.Settings.Common.Appearance.system)
                    }
                }
            )
            .disposed(by: disposeBag)

        apiWrapper
            .getCurrentNotificationState()
            .trackError(errorTracker)
            .trackActivity(initialLoadingTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { state in
                    enableNotificationsSubject.onNext(state.enable)
                    enableAccountBalanceWarningSubject.onNext(state.money)
                }
            )
            .disposed(by: disposeBag)

        // MARK: Нажатие на "Показывать уведомления"

        input.showNotificationTrigger
            .skip(1)
            .withLatestFrom(enableNotificationsSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isEnabled -> Driver<NotificationResponseData?> in
                guard let self = self else {
                    return .empty()
                }

                return self.apiWrapper
                    .setNotificationEnableState(isEnabled: !isEnabled)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] state in
                    enableNotificationsSubject.onNext(state.enable)
                    self?.logNotificationSettingChanged(
                        "push_notifications",
                        isEnabled: state.enable
                    )
                }
            )
            .disposed(by: disposeBag)

        // MARK: Нажатие на "Оповестить о недостатке средств"

        input.moneyTrigger
            .skip(1)
            .withLatestFrom(enableAccountBalanceWarningSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isActive -> Driver<NotificationResponseData?> in
                guard let self = self else {
                    return .empty()
                }

                return self.apiWrapper
                    .setNotificationMoneyState(isActive: !isActive)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] state in
                    enableAccountBalanceWarningSubject.onNext(state.money)
                    self?.logNotificationSettingChanged(
                        "balance_warning",
                        isEnabled: state.money
                    )
                }
            )
            .disposed(by: disposeBag)

        // MARK: Нажатие на "Использовать CallKit"

        input.callkitTrigger
            .skip(1)
            .withLatestFrom(enableCallkitSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isActive -> Driver<Bool?> in
                guard let self = self else {
                    return .empty()
                }

                let newState = !isActive

                return self.pushNotificationService
                    .registerForPushNotifications(
                        voipToken: newState ? self.accessService.voipToken : nil
                    )
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { _ in newState }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] newState in
                    self?.accessService.prefersVoipForCalls = newState
                    self?.logSettingToggled(
                        "callkit",
                        isEnabled: newState,
                        screen: "notifications_settings"
                    )

                    enableCallkitSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)

        // MARK: Нажатие на "Громкоговоритель по умолчанию"

        input.speakerTrigger
            .skip(1)
            .withLatestFrom(enableSpeakerByDefaultSubject.asDriver(onErrorJustReturn: false))
            .drive(
                onNext: { [weak self] isActive in
                    let newState = !isActive

                    self?.accessService.prefersSpeakerForCalls = newState
                    self?.logSettingToggled(
                        "speaker_by_default",
                        isEnabled: newState,
                        screen: "notifications_settings"
                    )

                    enableSpeakerByDefaultSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)

        // MARK: - Обработка нажатия "Показывать на карте"

        input.showCamerasOnMapTrigger
            .skip(1)
            .withLatestFrom(showCamerasOnMapSubject.asDriver(onErrorJustReturn: false))
            .drive(
                onNext: { [weak self] state in
                    guard state == self?.accessService.showList else {
                        return
                    }

                    let newState = !state

                    self?.accessService.showList = newState
                    self?.logSettingToggled(
                        "show_cameras_on_map",
                        isEnabled: newState,
                        screen: "settings"
                    )
                    showCamerasOnMapSubject.onNext(newState)
                }
            )
            .disposed(by: disposeBag)

        input.languageTrigger
            .debounce(.milliseconds(25))
            .drive(
                onNext: {
                    Self.openApplicationSettings()
                }
            )
            .disposed(by: disposeBag)

        // MARK: Отображение имени. Актуализируем при каждом обновлении имени в настройках

        let currentName = Driver<APIClientName?>.merge(
            .just(accessService.clientName),
            NotificationCenter.default.rx.notification(.userNameUpdated)
                .map { [weak self] _ in self?.accessService.clientName }
                .asDriver(onErrorJustReturn: nil)
        )

        let nameAsString = currentName
            .asDriver(onErrorJustReturn: nil)
            .map { clientName -> String? in
                [clientName?.name, clientName?.patronymic]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }

        let phone = accessService.clientPhoneNumber?.formattedNumberFromRawNumber

        // MARK: Переход назад

        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)

        // MARK: Редактирование имени

        input.editNameTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.editName)
                }
            )
            .disposed(by: disposeBag)

        // MARK: Выход из аккаунта

        bindLogout(input, activityTracker: activityTracker, errorTracker: errorTracker)

        input.showApereanceApert
            .drive(
                onNext: { [weak self] in
                    let systemAction = UIAlertAction(
                        title: L10n.Settings.Common.Appearance.system,
                        style: .default
                    ) { _ in
                        ThemeManager.shared.setTheme(.unspecified)
                        appereanceButtonTextSubject.onNext(L10n.Settings.Common.Appearance.system)
                        self?.logThemeChanged("system")
                    }

                    let lightAction = UIAlertAction(
                        title: L10n.Settings.Common.Appearance.light,
                        style: .default
                    ) { _ in
                        ThemeManager.shared.setTheme(.light)
                        appereanceButtonTextSubject.onNext(L10n.Settings.Common.Appearance.light)
                        self?.logThemeChanged("light")
                    }

                    let darkAction = UIAlertAction(
                        title: L10n.Settings.Common.Appearance.dark,
                        style: .default
                    ) { _ in
                        ThemeManager.shared.setTheme(.dark)
                        appereanceButtonTextSubject.onNext(L10n.Settings.Common.Appearance.dark)
                        self?.logThemeChanged("dark")
                    }

                    let cancelAction = UIAlertAction(title: L10n.Common.cancel, style: .destructive)

                    self?.router.trigger(
                        .dialog(
                            title: L10n.Settings.Common.Appearance.sheetTitle,
                            message: L10n.Settings.Common.Appearance.sheetMessage,
                            actions: [systemAction, lightAction, darkAction, cancelAction],
                            style: .actionSheet
                        )
                    )
                }
            )
            .disposed(by: disposeBag)

        // MARK: Удаление аккаунта

        bindAccountDeletion(input, activityTracker: activityTracker, errorTracker: errorTracker)

        input.callKitHintTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.showModal(withContent: .aboutCallKit))
                }
            )
            .disposed(by: disposeBag)

        input.addressOrderHintTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.showModal(withContent: .aboutAddressOrder))
                }
            )
            .disposed(by: disposeBag)

        input.addressOrderTrigger
            .drive(
                onNext: { [weak self] in

                    let cancelAction = UIAlertAction(
                        title: L10n.Common.cancel,
                        style: .cancel
                    ) { _ in
                        // nothing
                    }
                    let okAction = UIAlertAction(
                        title: L10n.Common.reset,
                        style: .default
                    ) { _ in
                        resetConfirmed.accept(())
                        self?.logAddressOrderReset()
                        NotificationCenter.default.post(name: .addressOrderReset, object: nil)
                    }

                    let resetOrderAlertTitle = L10n.Settings.Common.AddressOrder.resetDialogTitle
                    let resetOrderAlertText = L10n.Settings.Common.AddressOrder.resetDialogMessage

                    self?.router.trigger(
                        .dialog(
                            title: resetOrderAlertTitle,
                            message: resetOrderAlertText,
                            actions: [cancelAction, okAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)

        return Output(
            name: nameAsString,
            phone: .just(phone),
            enableNotifications: enableNotificationsSubject.asDriverOnErrorJustComplete(),
            enableAccountBalanceWarning: enableAccountBalanceWarningSubject.asDriverOnErrorJustComplete(),
            enableCallkit: enableCallkitSubject.asDriverOnErrorJustComplete(),
            enableSpeakerByDefault: enableSpeakerByDefaultSubject.asDriverOnErrorJustComplete(),
            showCamerasOnMap: showCamerasOnMapSubject.asDriverOnErrorJustComplete(),
            currentLanguage: currentLanguage,
            displaySettings: displaySettingsSubject.asDriverOnErrorJustComplete(),
            appereanceButtonText: appereanceButtonTextSubject.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver(),
            shouldShowInitialLoading: initialLoadingTracker.asDriver(),
            resetDidComplete: resetDidComplete.asDriverOnErrorJustComplete()
        )
    }
}
