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
    
    private var apiWrapper: APIWrapper
    private var router: WeakRouter<PaymentsRoute>
    
    private let items: BehaviorSubject<[APIPaymentsListAccount]>
    private let address: BehaviorSubject<String>
    
    init(
        address: String,
        items: [APIPaymentsListAccount],
        apiWrapper: APIWrapper,
        router: WeakRouter<PaymentsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.items = BehaviorSubject<[APIPaymentsListAccount]>(value: items)
        self.address = BehaviorSubject<String>(value: address)
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
        
        input.fullVersionPersonalAccountTrigger
            .drive(
            onNext: { [weak self] linkStr in
                guard let uLinkStr = linkStr, let lcabUrl = URL(string: uLinkStr) else {
                    return
                }
                
                self?.router.trigger(.safariPage(url: lcabUrl))
            }
        )
        .disposed(by: disposeBag)
        
        return Output(
            items: items.asDriver(onErrorJustReturn: []),
            address: address.asDriver(onErrorJustReturn: "")
        )
    }
    
}

extension PayContractViewModel {
    
    struct Input {
        let fullVersionPersonalAccountTrigger: Driver<String?>
        let payContractTrigger: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let items: Driver<[APIPaymentsListAccount]>
        let address: Driver<String>
    }
    
}
