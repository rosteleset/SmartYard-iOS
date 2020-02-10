//
//  AuthByContractNumViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class AuthByContractNumViewModel: BaseViewModel {
    
    private let router: WeakRouter<AppRoute>
    
    init(router: WeakRouter<AppRoute>, phoneNumber: String) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        input.forgetPassTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.forgetEverythingTapped
            .drive(
                onNext: {
                   // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.noContractTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.signInTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension AuthByContractNumViewModel {
    
    struct Input {
        let forgetPassTapped: Driver<Void>
        let forgetEverythingTapped: Driver<Void>
        let noContractTapped: Driver<Void>
        let signInTapped: Driver<Void>
    }
    
    struct Output {
        // TODO: выяснить, как будет обрабатываться проверка данных
        // let checkDataTrigger: Driver<Bool>
    }
    
}
