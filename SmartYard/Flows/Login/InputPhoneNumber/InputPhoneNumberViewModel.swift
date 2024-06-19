//
//  InputPhoneNumberViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class InputPhoneNumberViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    
    init(accessService: AccessService, apiWrapper: APIWrapper, router: WeakRouter<AppRoute>) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
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
                        let message = NSLocalizedString("You are requesting a code too often. Please try again later", comment: "")
                        self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: message))
                        
                    default:
                        self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        input.inputPhoneText
            .distinctUntilChanged()
            .filter { $0.count == AccessService.shared.phoneLengthWithoutPrefix }
            .do(
                onNext: { phone in
                    tempPhoneSubject.onNext(phone)
                }
            )
            .flatMapLatest { [weak self] phone -> Driver<RequestCodeResponseData?> in
                guard let self = self else {
                    return .just(nil)
                }

                return self.apiWrapper.requestCode(userPhone: AccessService.shared.phonePrefix + phone)
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
                            self.router.trigger(.alert(
                                title: NSLocalizedString("Error", comment: ""),
                                message: NSLocalizedString("Missing confirmation number", comment: "")
                            ))
                            return
                        }
                        self.router.trigger(.authByOutgoingCall(phoneNumber: phone, confirmPhoneNumber: confirmNumber))
                    case .flashCall:
                        self.router.trigger(.pinCode(phoneNumber: phone, isInitial: true, useFlashCall: true))
                    case .otp:
                        self.router.trigger(.pinCode(phoneNumber: phone, isInitial: true, useFlashCall: false))
                    }
                    
                }
            )
            .disposed(by: disposeBag)
    
        input.backButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .selectProvider
                    
                    self?.router.trigger(.selectProvider)
                }
            )
            .disposed(by: disposeBag)
            
        input.fixProviderButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.accessService.appState = .selectProvider
                    
                    self?.router.trigger(.selectProvider)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete(),
            selectedProviderName: .just(accessService.providerName)
        )
    }
    
}

extension InputPhoneNumberViewModel {
    
    struct Input {
        let inputPhoneText: Driver<String>
        let backButtonTapped: Driver<Void>
        let fixProviderButtonTapped: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
        let selectedProviderName: Driver<String>
    }
    
}
