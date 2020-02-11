//
//  ServiceIsActivatedViewModel.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class ServiceIsActivatedViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    init(router: WeakRouter<SettingsRoute>) {
        self.router = router
    }
    
    func transform(_ input: Input) -> Output {
        input.dismissTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.changePlanTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension ServiceIsActivatedViewModel {
    
    struct Input {
        let dismissTrigger: Driver<Void>
        let changePlanTrigger: Driver<Void>
    }

    struct Output {}
    
}
