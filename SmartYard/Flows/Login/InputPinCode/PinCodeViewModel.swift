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

class PinCodeViewModel: BaseViewModel  {
    
    let router: WeakRouter<AppRoute>
    
    init(router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    let incorrectPinTrigger = PublishSubject<Bool>()
    
    func transform(input: Input) -> Output {
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
        
        return Output(checkPinTrigger: incorrectPinTrigger.asDriverOnErrorJustComplete())
    }
    
}

extension PinCodeViewModel {
    
    struct Input {
        let inputPinText: Driver<String>
        let fixPhoneNumberButtonTapped: Driver<Void>
        let sendCodeAgainButtonDidTapped: Driver<Void>
    }
    
    struct Output {
        let checkPinTrigger: Driver<Bool>
    }
    
}
