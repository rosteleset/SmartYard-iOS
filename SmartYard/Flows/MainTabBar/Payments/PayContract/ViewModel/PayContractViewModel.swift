//
//  PayContractViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 03.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
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
                onNext: { [weak self] args in
                    let (clientID, recommendedSum, contractNumber) = args
                    
                    guard let self = self else {
                        return
                    }
                    
                    self.router.trigger(
                        .paymentPopup(
                            apiWrapper: self.apiWrapper,
                            clientId: clientID,
                            recommendedSum: recommendedSum,
                            constracNumber: contractNumber
                        )
                    )
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
        let payContractTrigger: Driver<(String, Double?, String?)>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let items: Driver<[APIPaymentsListAccount]>
        let address: Driver<String>
    }
    
}
