//
//  PaymentPopupViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 14.05.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class PaymentPopupViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let clientId: String
    
    init(
        apiWrapper: APIWrapper,
        clientId: String
    ) {
        self.apiWrapper = apiWrapper
        self.clientId = clientId
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
    
        input.preparePay
            .flatMapLatest { [weak self] amount -> Driver<PayPrepareResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.payPrepare(clientId: self.clientId, amount: amount)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] innerPaymentId in
                    print("INNER PAYMENT ID: \(innerPaymentId)")
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension PaymentPopupViewModel {
    
    struct Input {
        let preparePay: Driver<String>
    }
    
    struct Output {

    }
    
}
