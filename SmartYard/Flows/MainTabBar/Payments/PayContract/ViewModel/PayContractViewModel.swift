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
    
    private var items: BehaviorSubject<[PaymentAddressItem]>
    private var selectedIndex: BehaviorSubject<Int>
    private var apiWrapper: APIWrapper
    private var router: WeakRouter<PaymentsRoute>
    
    init(
        items: [PaymentAddressItem],
        selectedIndex: Int,
        apiWrapper: APIWrapper,
        router: WeakRouter<PaymentsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.items = BehaviorSubject<[PaymentAddressItem]>(value: items)
        self.selectedIndex = BehaviorSubject<Int>(value: selectedIndex)
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
            items: items.asDriver(onErrorJustReturn: []),
            selectedIndex: selectedIndex.asDriverOnErrorJustComplete()
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
        let items: Driver<[PaymentAddressItem]>
        let selectedIndex: Driver<Int>
    }
    
}
