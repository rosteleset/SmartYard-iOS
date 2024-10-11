//
//  PinCodeViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity

import Foundation
import RxCocoa
import RxSwift
import XCoordinator
import FirebaseCrashlytics
import FirebaseMessaging

class AuthByMobileProviderViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    let activityTracker = BehaviorSubject(value: false)
    let waitingForActivation = BehaviorSubject(value: false)
//    let timerNotActive = PublishSubject<Bool>()
//    var pollingCounter = 0

    private let phoneNumber: String
    private var requestId: String
    
    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        router: WeakRouter<AppRoute>,
        phoneNumber: String,
        requestId: String
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
        self.phoneNumber = phoneNumber
        self.requestId = requestId
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()

//        let timer = Observable<Int>
//            .interval(.seconds(3), scheduler: MainScheduler.instance)
//            .asDriverOnErrorJustComplete()
//            .drive(
//                onNext: { [weak self] _ in
                    
//                    print("DEBUG polling in progress", self?.pollingCounter)
//                    self?.pollingCounter = (self?.pollingCounter ?? 0) + 1
//                    self?.runPolling(active: true)
//                }
//            )
        
//        timer.disposed(by: disposeBag)

        let prepareTransitionTrigger = PublishSubject<Void>()
        
        self.activityTracker.onNext(true)
        self.waitingForActivation.onNext(true)
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    self?.activityTracker.onNext(false)

                    switch nsError.code {
                    case 424:
                        self?.router.trigger(.pinCode(phoneNumber: self?.phoneNumber ?? "", isInitial: false))
                    case 429:
                        let message = "Вы запрашиваете подтверждение слишком часто. Пожалуйста, попробуйте позже"
                        self?.router.trigger(.alert(title: "Ошибка", message: message))
                        
                    default:
                        self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
//        timerNotActive.asDriverOnErrorJustComplete()
//            .drive(
//                onNext: { isactive in
//                    guard isactive == true else {
//                        return
//                    }
//                    timer.dispose()
//                }
//            )
//            .disposed(by: disposeBag)
//
//        timerNotActive.onNext(false)

        input.fixPhoneNumberButtonTapped
            .drive(
                onNext: { [weak self] in
//                    self?.timerNotActive.onNext(true)
                    self?.activityTracker.onNext(false)

                    self?.accessService.appState = .phoneNumber
                    self?.router.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
        
        input.sendConfirmAgainButtonTapped
            .flatMapLatest { [weak self] _ -> Driver<RequestCodeResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                self.activityTracker.onNext(false)

                if let fcmToken = Messaging.messaging().fcmToken {
                    return self.apiWrapper.requestCode(userPhone: "8" + self.phoneNumber, type: "push", pushToken: fcmToken)
                        .trackActivity(activityTracker)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                }
                return self.apiWrapper.requestCode(userPhone: "8" + self.phoneNumber, type: "sms")
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] response in
                    guard let self = self else {
                        return
                    }
                    
                    switch response {
                    case .outgoingCall(let confirmNumbers):
                        guard let confirmNumber = confirmNumbers.first else {
                            self.accessService.appState = .smsCode(phoneNumber: self.phoneNumber)
                            return
                        }
                        self.accessService.appState = .authByOutgoingCall(
                            phoneNumber: self.phoneNumber,
                            confirmPhoneNumber: confirmNumber
                        )
                    case .pushMobile(let requestId):
                        self.accessService.appState = .authByMobileProvider(
                            phoneNumber: self.phoneNumber,
                            requestId: requestId
                        )
                    default:
                        self.accessService.appState = .smsCode(phoneNumber: self.phoneNumber)
                    }
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] response in
                    guard let self = self else {
                        return
                    }
                    
                    switch response {
                    case .outgoingCall(let confirmNumbers):
                        guard let confirmNumber = confirmNumbers.first else {
                            self.router.trigger(.alert(title: "Ошибка", message: "Отсутствует номер для подтверждения"))
                            return
                        }
                        self.router.trigger(.authByOutgoingCall(phoneNumber: self.phoneNumber, confirmPhoneNumber: confirmNumber))
                    case .pushMobile(let requestId):
                        self.activityTracker.onNext(true)
                        self.requestId = requestId
                    default:
//                        self.timerNotActive.onNext(true)
                        self.router.trigger(.pinCode(phoneNumber: self.phoneNumber, isInitial: true))
                    }
                    
                }
            )
            .disposed(by: disposeBag)
                
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(waitingForActivation.asDriver(onErrorJustReturn: false))
            .isTrue()
            .mapToVoid()
            .flatMapLatest { [weak self] () -> Driver<CheckPhoneResponseData?> in
                    guard let self = self else {
                        return .just(nil)
                    }

                    return self.apiWrapper.confirmCode(
                            userPhone: "8" + self.phoneNumber,
                            type: "push",
                            requestId: self.requestId
                        )
                        .trackActivity(activityTracker)
//                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }
            .do(
                onNext: { [weak self] data in
                    guard let data = data, let self = self  else {
                        return
                    }
                    
                    self.activityTracker.onNext(true)

                    self.accessService.accessToken = data.accessToken
                    self.accessService.clientName = data.name
                    self.accessService.clientPhoneNumber = self.phoneNumber
                    self.accessService.appState = .userName

                    // когда пользователь авторизовался уже после инициализации Crashlytics, то надо обновить  UserId
                    Crashlytics.crashlytics().setUserID(self.accessService.clientPhoneNumber ?? "unknown")

                }
            )
            .ignoreNil()
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] data in
                    self?.activityTracker.onNext(false)
                    self?.router.trigger(.userName(preloadedName: data.name))
                }
            )
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(.authorizationFailed)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] _ in
                    self?.activityTracker.onNext(false)
                    guard let self = self else {
                        return
                    }
                    self.router.trigger(.pinCode(phoneNumber: self.phoneNumber, isInitial: false))
                }
            )
            .disposed(by: disposeBag)
                
        NotificationCenter.default.rx.notification(.authorizationCompleted)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    self?.activityTracker.onNext(false)
                    guard let self = self,
                          let userInfo = notification.userInfo,
                          let token = userInfo["accessToken"] as? String,
                          let name = userInfo["name"] as? String else {
                        return
                    }
                    let clientname = APIClientName(name: name, patronymic: userInfo["patronymic"] as? String)
                    print("DEBUG", self.accessService.appState)
                    
                    if let accessToken = self.accessService.accessToken {
                        return
                    }
                    
                    switch self.accessService.appState {
                    case .phoneNumber:
                        return
                    default:
                        self.accessService.accessToken = token
                        self.accessService.clientName = clientname
                        self.accessService.clientPhoneNumber = self.phoneNumber
                        self.accessService.appState = .userName
    //
                        // когда пользователь авторизовался уже после инициализации Crashlytics, то надо обновить  UserId
                        Crashlytics.crashlytics().setUserID(self.accessService.clientPhoneNumber ?? "unknown")
                        
                        self.router.trigger(.userName(preloadedName: clientname))

                    }
                    
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            phoneNumber: .just(phoneNumber),
            isLoading: self.activityTracker.asDriver(onErrorJustReturn: false),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
//    func runPolling(active: Bool) {
//        let pollingInProgress = PublishSubject<Bool>()
//
//        pollingInProgress.asDriverOnErrorJustComplete()
//            .distinctUntilChanged()
//            .filter { $0 == true }
//            .mapToVoid()
//            .flatMapLatest { [weak self] () -> Driver<CheckPhoneResponseData?> in
//                    guard let self = self else {
//                        return .just(nil)
//                    }
//
//                    return self.apiWrapper.confirmCode(
//                            userPhone: "8" + self.phoneNumber,
//                            type: "push",
//                            requestId: self.requestId
//                        )
//                        .asDriver(onErrorJustReturn: nil)
//            }
//            .do(
//                onNext: { [weak self] data in
//                    guard let data = data, let self = self  else {
//                        return
//                    }
//                    pollingInProgress.onNext(false)
//                    self.timerNotActive.onNext(true)
//                    self.activityTracker.onNext(true)
//
//                    self.accessService.accessToken = data.accessToken
//                    self.accessService.clientName = data.name
//                    self.accessService.clientPhoneNumber = self.phoneNumber
//                    self.accessService.appState = .userName
//
//                    // когда пользователь авторизовался уже после инициализации Crashlytics, то надо обновить  UserId
//                    Crashlytics.crashlytics().setUserID(self.accessService.clientPhoneNumber ?? "unknown")
//
//                }
//            )
//            .ignoreNil()
//            .delay(.milliseconds(100))
//            .drive(
//                onNext: { [weak self] data in
//                    self?.activityTracker.onNext(false)
//                    self?.router.trigger(.userName(preloadedName: data.name))
//                }
//            )
//            .disposed(by: disposeBag)
//
//        pollingInProgress.onNext(active)
//    }
    
}

extension AuthByMobileProviderViewModel {
    
    struct Input {
        let fixPhoneNumberButtonTapped: Driver<Void>
        let sendConfirmAgainButtonTapped: Driver<Void>
    }
    
    struct Output {
        let phoneNumber: Driver<String>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}

// swiftlint:enable function_body_length cyclomatic_complexity
