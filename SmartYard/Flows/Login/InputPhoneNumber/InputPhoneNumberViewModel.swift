//
//  InputPhoneNumberViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxSwift
import RxCocoa
import XCoordinator
import FirebaseMessaging

class InputPhoneNumberViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    init(accessService: AccessService, apiWrapper: APIWrapper, router: WeakRouter<AppRoute>) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        let tempPhoneSubject = BehaviorSubject<String?>(value: nil)
        let tempPhone = tempPhoneSubject.asDriver(onErrorJustReturn: nil)
        
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 429:
                        let message = "Вы запрашиваете код слишком часто. Пожалуйста, попробуйте позже"
                        self?.router.trigger(.alert(title: "Ошибка", message: message))
                        
                    default:
                        self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        input.inputPhoneText
            .distinctUntilChanged()
            .filter { $0.count == Constants.phoneLengthWithoutPrefix }
            .do(
                onNext: { phone in
                    tempPhoneSubject.onNext(phone)
                }
            )
            .flatMapLatest { [weak self] phone -> Driver<RequestCodeResponseData?> in
                guard let self = self else {
                    return .just(nil)
                }

                if let fcmToken = Messaging.messaging().fcmToken {
                    return self.apiWrapper.requestCode(userPhone: "8" + phone, type: "push", pushToken: fcmToken)
                        .trackActivity(activityTracker)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                }
                return self.apiWrapper.requestCode(userPhone: "8" + phone)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(tempPhone.ignoreNil()) { ($0, $1) }
            .do(
                onNext: { [weak self] response, phoneNumber in
                    switch response {
                    case .outgoingCall(let confirmNumbers):
                        guard let confirmNumber = confirmNumbers.first else {
                            self?.accessService.appState = .smsCode(phoneNumber: phoneNumber)
                            return
                        }
                        self?.accessService.appState = .authByOutgoingCall(
                            phoneNumber: phoneNumber,
                            confirmPhoneNumber: confirmNumber
                        )
                    case .pushMobile(let requestId):
                        self?.accessService.appState = .authByMobileProvider(
                            phoneNumber: phoneNumber,
                            requestId: requestId
                        )
                    default:
                        self?.accessService.appState = .smsCode(phoneNumber: phoneNumber)
                    }
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] response, phone in
                    guard let self = self else {
                        return
                    }
                    
                    switch response {
                    case .outgoingCall(let confirmNumbers):
                        guard let confirmNumber = confirmNumbers.first else {
                            self.router.trigger(.alert(title: "Ошибка", message: "Отсутствует номер для подтверждения"))
                            return
                        }
                        self.router.trigger(.authByOutgoingCall(phoneNumber: phone, confirmPhoneNumber: confirmNumber))
                    case .pushMobile(let requestId):
                        self.router.trigger(.authByMobileProvider(phoneNumber: phone, requestId: requestId))
                    default:
                        self.router.trigger(.pinCode(phoneNumber: phone, isInitial: true))
                    }
                    
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension InputPhoneNumberViewModel {
    
    struct Input {
        let inputPhoneText: Driver<String>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
// swiftlint:enable function_body_length
