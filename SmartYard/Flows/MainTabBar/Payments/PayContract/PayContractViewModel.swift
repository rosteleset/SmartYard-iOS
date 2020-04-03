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
    
    var items: BehaviorSubject<[PaymentAddressItem]>
    var apiWrapper: APIWrapper
    var router: WeakRouter<PaymentsRoute>
    
    init(
        items: [PaymentAddressItem],
        apiWrapper: APIWrapper,
        router: WeakRouter<PaymentsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.items = BehaviorSubject<[PaymentAddressItem]>(value: items)
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        return Output(items: items.asDriver(onErrorJustReturn: []))
    }
    
}

extension PayContractViewModel {
    
    struct Input {
        
        let fullVersionPersonalAccountTrigger: Driver<Void>
        let payContractTrigger: Driver<Void>
        
    }
    
    struct Output {
        
        let items: Driver<[PaymentAddressItem]>
        
    }
    
}
