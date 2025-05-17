//
//  AdvancedSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxCocoa
import RxSwift
import XCoordinator
import SmartYardSharedDataFramework
import WebKit
import FirebaseMessaging
import SkeletonView

// swiftlint:disable:next type_body_length
final class CommonSettingsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private let router: WeakRouter<SettingsRoute>
    
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
                            title: NSLocalizedString("Error", comment: ""),
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
        let appereanceButtonTextSubject = BehaviorSubject<String>(value: NSLocalizedString("System", comment: ""))
        let resetConfirmed = PublishRelay<Void>()
        let resetDidComplete = resetConfirmed
            .do(onNext: { [weak self] in
                self?.accessService.userPreferredAddressOrder = []
            })

        if #available(iOS 13.0, *) {
            ThemeManager.shared.currentTheme
                .subscribe(
                    onNext: { style in
                        switch style {
                        case .unspecified:
                            appereanceButtonTextSubject.onNext(NSLocalizedString("System", comment: ""))
                        case .light:
                            appereanceButtonTextSubject.onNext(NSLocalizedString("Light", comment: ""))
                        case .dark:
                            appereanceButtonTextSubject.onNext(NSLocalizedString("Dark", comment: ""))
                        @unknown default:
                            Logger.logWarning("!! Unknown UIUserInterfaceStyle encountered: \(style)")
                            
                            appereanceButtonTextSubject.onNext(NSLocalizedString("System", comment: ""))
                        }
                    }
                )
                .disposed(by: disposeBag)
        } else {
            // Реализации темной темы для ios 12 нет.
        }
        
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
                onNext: { state in
                    enableNotificationsSubject.onNext(state.enable)
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
                onNext: { state in
                    enableAccountBalanceWarningSubject.onNext(state.money)
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
                    
                    enableCallkitSubject.onNext(newState)
                    
                    // Если включен CallKit, то динамик по-умолчанию всегда будет обычный
                    if newState {
                        self?.accessService.prefersSpeakerForCalls = false
                        enableSpeakerByDefaultSubject.onNext(false)
                    }
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Нажатие на "Громкоговоритель по умолчанию"
        
        input.speakerTrigger
            .skip(1)
            .filter { [weak self] in
                self?.accessService.prefersVoipForCalls == false
            }
            .withLatestFrom(enableSpeakerByDefaultSubject.asDriver(onErrorJustReturn: false))
            .drive(
                onNext: { [weak self] isActive in
                    let newState = !isActive
                    
                    self?.accessService.prefersSpeakerForCalls = newState
                    
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
                    showCamerasOnMapSubject.onNext(newState)
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
        
        input.logoutTrigger
            .drive(
                onNext: { [weak self] in
                    let noAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil)
                    
                    let yesAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .destructive) { [weak self] _ in
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
                                    self?.accessService.logout()
                                }
                            )
                            .disposed(by: self.disposeBag)
                    }
                    
                    self?.router.trigger(
                        .dialog(
                            title: NSLocalizedString("Exiting the application", comment: ""),
                            message: NSLocalizedString("Are you sure you want to log out of your account?", comment: ""),
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

        input.showApereanceApert
            .drive(
                onNext: { [weak self] in
                    let systemAction = UIAlertAction(title: NSLocalizedString("System", comment: ""), style: .default) { _ in
                        if #available(iOS 13.0, *) { ThemeManager.shared.setTheme(.unspecified) }
                        appereanceButtonTextSubject.onNext(NSLocalizedString("System", comment: ""))
                    }
                    let lightAction = UIAlertAction(title: NSLocalizedString("Light", comment: ""), style: .default) { _ in
                        if #available(iOS 13.0, *) { ThemeManager.shared.setTheme(.light) }
                        appereanceButtonTextSubject.onNext(NSLocalizedString("Light", comment: ""))
                    }
                    let darkAction = UIAlertAction(title: NSLocalizedString("Dark", comment: ""), style: .default) { _ in
                        if #available(iOS 13.0, *) { ThemeManager.shared.setTheme(.dark) }
                        appereanceButtonTextSubject.onNext(NSLocalizedString("Dark", comment: ""))
                    }
                    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .destructive)

                    self?.router.trigger(
                        .dialog(
                            title: NSLocalizedString("Select Appearance", comment: ""),
                            message: NSLocalizedString("Please choose your preferred appearance theme.", comment: ""),
                            actions: [systemAction, lightAction, darkAction, cancelAction],
                            style: .actionSheet
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Удаление аккаунта
        
        input.deleteAccountTrigger
            .drive(
                onNext: { [weak self] in
                    let noAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: nil)
                    
                    let yesAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .destructive) { [weak self] _ in
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
                            title: NSLocalizedString("Account deleting", comment: ""),
                            message: NSLocalizedString("Are you sure you want to delete your account? All previously added addresses will be deleted", comment: ""),
                            actions: [noAction, yesAction],
                            style: .alert
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
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
                        title: NSLocalizedString("Cancel", comment: ""),
                        style: .cancel
                    ) { _ in
                        // nothing
                    }
                    let okAction = UIAlertAction(
                        title: NSLocalizedString("Reset", comment: ""),
                        style: .default
                    ) { _ in
                        resetConfirmed.accept(())
                        NotificationCenter.default.post(name: .addressOrderReset, object: nil)
                    }
                    
                    let resetOrderAlertTitle = NSLocalizedString(
                        "Reset address order?",
                        comment: ""
                    )
                    let resetOrderAlertText = NSLocalizedString(
                        "This will restore the default sorting.",
                        comment: ""
                    )
                    
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
            displaySettings: displaySettingsSubject.asDriverOnErrorJustComplete(),
            appereanceButtonText: appereanceButtonTextSubject.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver(),
            shouldShowInitialLoading: initialLoadingTracker.asDriver(),
            resetDidComplete: resetDidComplete.asDriverOnErrorJustComplete()
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
        let displaySettings: Driver<(Bool, Bool)>
        let appereanceButtonText: Driver<String>
        let isLoading: Driver<Bool>
        let shouldShowInitialLoading: Driver<Bool>
        let resetDidComplete: Driver<Void>
    }
    
}
