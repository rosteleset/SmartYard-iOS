//
//  AdvancedSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxCocoa
import RxSwift
import XCoordinator

class AdvancedSettingsViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    private let name: String
    
    init(router: WeakRouter<SettingsRoute>, name: String) {
        self.router = router
        self.name = name
    }
    
    func transform(_ input: Input) -> Output {
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            name: .just(name),
            enableNotifications: .just(true),
            enableText: .just(true),
            ringtone: .just("Нота"),
            enableAccountBalanceWarning: .just(false),
            enableBiometry: .just(true),
            enablePinCode: .just(false)
        )
    }
    
}

extension AdvancedSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let name: Driver<String>
        let enableNotifications: Driver<Bool>
        let enableText: Driver<Bool>
        let ringtone: Driver<String>
        let enableAccountBalanceWarning: Driver<Bool>
        let enableBiometry: Driver<Bool>
        let enablePinCode: Driver<Bool>
    }
    
}
