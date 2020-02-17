//
//  NewAllowedPersonViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 17.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class NewAllowedPersonViewModel: BaseViewModel {
    
    private let router: WeakRouter<AppRoute>
    
    init(router: WeakRouter<AppRoute>) {
        self.router = router
    }
    
    func transform(_ input: Input) -> Output {
        input.closeTrigger
            .drive(
                onNext: {
            
                }
            )
            .disposed(by: disposeBag)
        
        input.addAccessTrigger
            .drive(
                onNext: {
                    
                }
            )
            .disposed(by: disposeBag)
        
        input.selectFromContactTrigger
            .drive(
                onNext: {
                    
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension NewAllowedPersonViewModel {
    
    struct Input {
        let closeTrigger: Driver<Void>
        let selectFromContactTrigger: Driver<Void>
        let addAccessTrigger: Driver<Void>
    }
    
    struct Output {
        
    }
    
}
