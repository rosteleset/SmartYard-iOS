//
//  PayContractViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 03.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class PayContractViewModel: BaseViewModel {
    
    private var items: BehaviorSubject<[APIPaymentsListAccount]>
    private var apiWrapper: APIWrapper
    private var router: WeakRouter<PaymentsRoute>
    
    init(
        items: [APIPaymentsListAccount],
        apiWrapper: APIWrapper,
        router: WeakRouter<PaymentsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.items = BehaviorSubject<[APIPaymentsListAccount]>(value: items)
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        input.payContractTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.paymentPopup)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            items: items.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension PayContractViewModel {
    
    struct Input {
        let fullVersionPersonalAccountTrigger: Driver<Void>
        let payContractTrigger: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let items: Driver<[APIPaymentsListAccount]>
    }
    
}
