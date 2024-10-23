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

final class PayContractViewModel: BaseViewModel {
    
    private var apiWrapper: APIWrapper
    private var router: WeakRouter<PaymentsRoute>
    
    private let items: BehaviorSubject<[PaymentsListAccount]>
    private let index: BehaviorSubject<Int?>
    
    init(
        index: Int,
        items: [APIPaymentsListAddress],
        apiWrapper: APIWrapper,
        router: WeakRouter<PaymentsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.items = BehaviorSubject<[PaymentsListAccount]>(
            value: items.flatMap { addressListItem in
                addressListItem.accounts.map {
                    PaymentsListAccount(address: addressListItem.address, account: $0)
                }
                
            }
        )
        let absoluteIndex = items.prefix(upTo: index).flatMap { $0.accounts }.count
        self.index = BehaviorSubject<Int?>(value: absoluteIndex)
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
            index: index.asDriver(onErrorJustReturn: nil)
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
        let items: Driver<[PaymentsListAccount]>
        let index: Driver<Int?>
    }
    
}
