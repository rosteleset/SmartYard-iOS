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
    
    func transform(input: Input) -> Output {
        
        return Output()
    }
}

extension PinCodeViewModel {
    
    struct Input {
        let pinCode: Driver<String?>
        let fixPhoneNumberButtonTapped: Driver<Void>
        let sendCodeAgainButtonDidTapped: Driver<Void>
    }
    
    struct Output {

    }
    
}
