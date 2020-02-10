//
//  InputPhoneNumberViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class InputPhoneNumberViewModel: BaseViewModel {
    
    let router: WeakRouter<AppRoute>
    
    init(router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        input.inputPhoneText
            .distinctUntilChanged()
            .filter { $0.count == Constants.phoneLengthWithoutPrefix }
            .drive(
                onNext: { [weak self] phoneNumber in
                    self?.router.trigger(.pinCode(phoneNumber: phoneNumber))
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension InputPhoneNumberViewModel {
    
    struct Input {
        let inputPhoneText: Driver<String>
    }
    
    struct Output {
        
    }
    
}
