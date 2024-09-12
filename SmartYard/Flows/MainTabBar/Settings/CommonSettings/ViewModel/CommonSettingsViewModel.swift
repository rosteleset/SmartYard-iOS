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

class CommonSettingsViewModel: BaseViewModel {
    
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
                    self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
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
        let enableListSubject = BehaviorSubject<Bool>(value: accessService.showList)
        let showCamerasSettingsSubject = BehaviorSubject<Bool>(value: accessService.cctvView == "userDefined")
        
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
        
        input.enableTrigger
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
        
        input.speakerTrigger
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
        input.enableListTrigger
            .withLatestFrom(enableListSubject.asDriverOnErrorJustComplete())
            .drive(
                onNext: { [weak self] state in
                    let newState = !state

                    self?.accessService.showList = newState
                    enableListSubject.onNext(newState)
                    print(">>> enableListTrigger: ", self?.accessService.showList)
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
                    
                    let yesAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .destructive) { _ in
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
                            actions: [noAction, yesAction]
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
        
        return Output(
            name: nameAsString,
            phone: .just(phone),
            enableNotifications: enableNotificationsSubject.asDriverOnErrorJustComplete(),
            enableAccountBalanceWarning: enableAccountBalanceWarningSubject.asDriverOnErrorJustComplete(),
            enableCallkit: enableCallkitSubject.asDriverOnErrorJustComplete(),
            enableSpeakerByDefault: enableSpeakerByDefaultSubject.asDriverOnErrorJustComplete(), 
            enableList: enableListSubject.asDriverOnErrorJustComplete(), 
            showCameras: showCamerasSettingsSubject.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver(),
            shouldShowInitialLoading: initialLoadingTracker.asDriver()
        )
    }
    
}

extension CommonSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let editNameTrigger: Driver<Void>
        let enableTrigger: Driver<Void>
        let moneyTrigger: Driver<Void>
        let callkitTrigger: Driver<Void>
        let speakerTrigger: Driver<Void>
        let enableListTrigger: Driver<Void>
        let logoutTrigger: Driver<Void>
        let callKitHintTrigger: Driver<Void>
    }
    
    struct Output {
        let name: Driver<String?>
        let phone: Driver<String?>
        let enableNotifications: Driver<Bool>
        let enableAccountBalanceWarning: Driver<Bool>
        let enableCallkit: Driver<Bool>
        let enableSpeakerByDefault: Driver<Bool>
        let enableList: Driver<Bool>
        let showCameras: Driver<Bool>
        let isLoading: Driver<Bool>
        let shouldShowInitialLoading: Driver<Bool>
    }
    
}
