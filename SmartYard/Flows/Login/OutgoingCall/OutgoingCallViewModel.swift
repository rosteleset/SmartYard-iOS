//
//  PinCodeViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator
import FirebaseCrashlytics
import FirebaseMessaging

class OutgoingCallViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    private let phoneNumber: String
    private let confirmPhone: String
    
    let activityTracker = BehaviorSubject(value: false)
    
    var timer: Timer?
    var timeEnd: Date?
    
    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        router: WeakRouter<AppRoute>,
        phoneNumber: String,
        confirmPhone: String
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
        self.phoneNumber = phoneNumber
        self.confirmPhone = confirmPhone
    }
    
    // swift-lint:disable:next function_body_length
    func transform(input: Input) -> Output {
        
        
        input.makeCallButtonTapped
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    if let phoneCallURL = URL(string: "tel://" + self.confirmPhone) {
                        let application = UIApplication.shared
                        if application.canOpenURL(phoneCallURL) {
                            application.open(phoneCallURL, options: [:], completionHandler: nil)
                        }
                      }
                }
            )
            .disposed(by: disposeBag)
        
        input.backButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .phoneNumber
                    
                    self?.router.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
        
        input.fixPhoneNumberButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .phoneNumber
                    
                    self?.router.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
        
        runPolling()
        
        return Output(
            phoneNumber: .just(phoneNumber),
            confirmPhoneNumber: .just(confirmPhone),
            isLoading: activityTracker.asDriver(onErrorJustReturn: false)
        )
    }
    
}

extension OutgoingCallViewModel {
    
    struct Input {
        let fixPhoneNumberButtonTapped: Driver<Void>
        let backButtonTapped: Driver<Void>
        let makeCallButtonTapped: Driver<Void>
    }
    
    struct Output {
        let phoneNumber: Driver<String>
        let confirmPhoneNumber: Driver<String>
        let isLoading: Driver<Bool>
    }
    
}

extension OutgoingCallViewModel {
    func runPolling() {
        let pollingInProgress = PublishSubject<Bool>()
        
        let timer = Observable<Int>
            .interval(.seconds(3), scheduler: MainScheduler.instance)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { _ in
                    pollingInProgress.onNext(true)
                }
            )
        
            timer.disposed(by: disposeBag)
        
        pollingInProgress.asDriverOnErrorJustComplete()
            .distinctUntilChanged()
            .filter { $0 == true }
            .mapToVoid()
            .flatMapLatest { [weak self] () -> Driver<CheckPhoneResponseData?> in
                    guard let self = self else {
                        return .just(nil)
                    }
                
                    return self.apiWrapper.checkPhone(userPhone: AccessService.shared.phonePrefix + self.phoneNumber)
                        .asDriver(onErrorJustReturn: nil)
            }
            .do(
                onNext: { [weak self] data in
                    pollingInProgress.onNext(false)
                    guard let data = data, let self = self  else {
                        return
                    }
                    self.activityTracker.onNext(true)
                    // Есть ответ.
                    timer.dispose()
                    
                    self.accessService.accessToken = data.accessToken
                    self.accessService.clientName = data.name
                    self.accessService.clientPhoneNumber = self.phoneNumber
                    self.accessService.appState = .userName
                    
                    // когда пользователь авторизовался уже после инициализации Crashlytics, то надо обновить  UserId
                    Crashlytics.crashlytics().setUserID(self.accessService.clientPhoneNumber ?? "unknown")
                    Messaging.messaging().isAutoInitEnabled = true
                    
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
        
        pollingInProgress.onNext(false)
    }
}
