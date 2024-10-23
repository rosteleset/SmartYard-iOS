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

final class PinCodeViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    private let phoneNumber: String
    
    init(accessService: AccessService, apiWrapper: APIWrapper, router: WeakRouter<AppRoute>, phoneNumber: String) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
        self.phoneNumber = phoneNumber
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let isPinCorrect = BehaviorSubject<Bool>(value: true)
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 403:
                        isPinCorrect.onNext(false)
                        
                    case 429:
                        let message = NSLocalizedString("You are requesting a code too often. Please try again later", comment: "")
                        self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: message))
                        
                    default:
                        self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.inputPinText
            .distinctUntilChanged()
            .do(
                onNext: { _ in
                    isPinCorrect.onNext(true)
                }
            )
            .filter { $0.count == Constants.pinLength }
            .flatMapLatest { [weak self] smsCode -> Driver<ConfirmCodeResponseData?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                return self.apiWrapper.confirmCode(userPhone: AccessService.shared.phonePrefix + self.phoneNumber, smsCode: smsCode)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] data in
                    self?.accessService.accessToken = data.accessToken
                    self?.accessService.clientName = data.name
                    self?.accessService.clientPhoneNumber = self?.phoneNumber
                    self?.accessService.appState = .userName
                    
                    // когда пользователь авторизовался уже после инициализации Crashlytics, то надо обновить  UserId
                    Crashlytics.crashlytics().setUserID(self?.accessService.clientPhoneNumber ?? "unknown")
                    Messaging.messaging().isAutoInitEnabled = true
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] data in
                    self?.router.trigger(.userName(preloadedName: data.name))
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
        
        input.backButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .phoneNumber
                    
                    self?.router.trigger(.phoneNumber)
                }
            )
            .disposed(by: disposeBag)
        
        input.sendCodeAgainButtonTapped
            .flatMapLatest { [weak self] _ -> Driver<RequestCodeResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.requestCode(userPhone: AccessService.shared.phonePrefix + self.phoneNumber)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive()
            .disposed(by: disposeBag)
        
        return Output(
            isPinCorrect: isPinCorrect.asDriverOnErrorJustComplete(),
            phoneNumber: .just(phoneNumber),
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension PinCodeViewModel {
    
    struct Input {
        let inputPinText: Driver<String>
        let fixPhoneNumberButtonTapped: Driver<Void>
        let backButtonTapped: Driver<Void>
        let sendCodeAgainButtonTapped: Driver<Void>
    }
    
    struct Output {
        let isPinCorrect: Driver<Bool>
        let phoneNumber: Driver<String>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}

