//
//  PinCodeViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 06.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class PinCodeViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<AppRoute>
    private let phoneNumber: String
    
    init(apiWrapper: APIWrapper, router: WeakRouter<AppRoute>, phoneNumber: String) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.phoneNumber = phoneNumber
    }
    
    let incorrectPinTrigger = PublishSubject<Bool>()
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let phoneNumberTrigger = PublishSubject<String>()
        
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.inputPinText
            .distinctUntilChanged()
            .filter { $0.count == Constants.pinLength }
            .flatMapLatest { [weak self] smsCode -> Driver<ConfirmCodeResponseData?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                return self.apiWrapper.confirmCode(userPhone: "8" + self.phoneNumber, smsCode: smsCode)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] data in
                    self?.router.trigger(data.name == nil ? .userName : .main)
                }
            )
            .disposed(by: disposeBag)
        
        input.viewWillAppearTrigger
            .drive(
                onNext: { [weak self] _ in
                    phoneNumberTrigger.onNext(self?.phoneNumber ?? "")
                }
            )
            .disposed(by: disposeBag)
        
        input.fixPhoneNumberButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.sendCodeAgainButtonTapped
            .drive(
                onNext: {
                    // TODO: send code again
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { error in
                    print(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            checkPinTrigger: incorrectPinTrigger.asDriverOnErrorJustComplete(),
            phoneNumberValueTrigger: phoneNumberTrigger.asDriver(onErrorJustReturn: ""),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension PinCodeViewModel {
    
    struct Input {
        let inputPinText: Driver<String>
        let fixPhoneNumberButtonTapped: Driver<Void>
        let sendCodeAgainButtonTapped: Driver<Void>
        let viewWillAppearTrigger: Driver<Bool>
    }
    
    struct Output {
        let checkPinTrigger: Driver<Bool>
        let phoneNumberValueTrigger: Driver<String>
        let isLoading: Driver<Bool>
    }
    
}

