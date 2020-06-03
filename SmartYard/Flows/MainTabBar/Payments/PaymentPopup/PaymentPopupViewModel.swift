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
    
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let isPaySuccessTrigger = PublishSubject<Bool>()
        
        input.payProcess
            .flatMapLatest { [weak self] args -> Driver<(Data?, PayPrepareResponseData?)?> in
                let (token, amount) = args
                
                guard let self = self else {
                    isPaySuccessTrigger.onNext(false)
                    print("_1")
                    return .empty()
                }
                print("client id: \(self.clientId)")

                return self.apiWrapper.payPrepare(clientId: self.clientId, amount: amount)
                    .trackError(errorTracker)
                    .map {
                        guard let response = $0 else {
                            isPaySuccessTrigger.onNext(false)
                            print("_2")
                            return nil
                        }
                        print("here")
                        
                        return (token, response)
                    }
                .asDriver(onErrorJustReturn: nil)
        }
            //.flatMapLatest { [weak self] args -> Driver<(String, SberbankPayProcessResponseData)?> in
            .flatMapLatest { [weak self] args -> Driver<SberbankPayProcessResponseData?> in
                print("_HERE")
                guard let self = self, let (token, response) = args, let orderNumber = response, let uToken = token?.base64EncodedString(), !uToken.isEmpty else {
                    isPaySuccessTrigger.onNext(false)
                    print("_3")
                    return .empty()
                }
                
                print("Token1: \(uToken)")
                
                print("Token: \(String(decoding: token!, as: UTF8.self))")
                
                return
                    self.apiWrapper.sberbankPayProcess(
                        merchant: "lanta",
                        orderNumber: orderNumber,
                        paymentToken: uToken
                        )
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
        }
        .drive(
            onNext: { response in
                print(response)
            }
        )
        .disposed(by: disposeBag)
//            .flatMapLatest { [weak self] args -> Driver<PayProcessResponseData?> in
//                guard let self = self,
//                      let (innerPaymentId, response) = args,
//                      let sberbankOrderId = response.data?.orderId
//                else {
//                    isPaySuccessTrigger.onNext(false)
//                    print("_5")
//                    return .empty()
//                }
//
//                return
//                    self.apiWrapper.payProcess(
//                            paymentId: innerPaymentId,
//                            sbId: sberbankOrderId
//                        )
//                        .trackError(errorTracker)
//                        .asDriver(onErrorJustReturn: nil)
//            }
//            .drive(
//                onNext: { result in
//                    // TODO: на серваке пока нет обработки успеха, поэтому будет считать, что все проходит успешно
//                    print("_6")
//                    isPaySuccessTrigger.onNext(true)
//                }
//            )
//            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    print(error)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(isPaySuccessTrigger: isPaySuccessTrigger.asDriver(onErrorJustReturn: false))
    }
    
}

extension PaymentPopupViewModel {
    
    struct Input {
        let payProcess: Driver<(Data?, String)>
    }
    
    struct Output {
        let isPaySuccessTrigger: Driver<Bool>
    }
    
}
