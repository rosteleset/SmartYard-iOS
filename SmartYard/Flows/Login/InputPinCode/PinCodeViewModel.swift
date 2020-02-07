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
    
    private let router: WeakRouter<AppRoute>
    private let phoneNumber: String
    
    init(router: WeakRouter<AppRoute>, phoneNumber: String) {
        self.router = router
        self.phoneNumber = phoneNumber
    }
    
    let incorrectPinTrigger = PublishSubject<Bool>()
    
    func transform(input: Input) -> Output {
        let phoneNumberTrigger = PublishSubject<String>()
        
        // TODO: Получить реальный пин-код от API
        input.inputPinText
            .distinctUntilChanged()
            .filter { $0.count == Constants.pinLength }
            .map { $0 == "1234" }
            .drive(
                onNext: { [weak self] isCorrectPin in
                    self?.incorrectPinTrigger.onNext(isCorrectPin)
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
        
        input.sendCodeAgainButtonapped
            .drive(
                onNext: {
                    // TODO: send code again
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            checkPinTrigger: incorrectPinTrigger.asDriverOnErrorJustComplete(),
            phoneNumberValueTrigger: phoneNumberTrigger.asDriver(onErrorJustReturn: "")
        )
    }
    
}

extension PinCodeViewModel {
    
    struct Input {
        let inputPinText: Driver<String>
        let fixPhoneNumberButtonTapped: Driver<Void>
        let sendCodeAgainButtonapped: Driver<Void>
        let viewWillAppearTrigger: Driver<Bool>
    }
    
    struct Output {
        let checkPinTrigger: Driver<Bool>
        let phoneNumberValueTrigger: Driver<String>
    }
    
}
