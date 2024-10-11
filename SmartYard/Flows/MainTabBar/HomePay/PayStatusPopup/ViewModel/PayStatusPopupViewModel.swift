//
//  PayStatusPopupViewModel.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 09.09.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity

import Foundation
import RxSwift
import RxCocoa
import XCoordinator
import UIKit

class PayStatusPopupViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let merchant: Merchant
    private var router: WeakRouter<HomePayRoute>

    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    private let orderId = BehaviorSubject<String?>(value: nil)
    private let errorTitle = BehaviorSubject<String?>(value: nil)
    private let errorMessage = BehaviorSubject<String?>(value: nil)
    private let isSuccessPay = BehaviorSubject<Bool>(value: false)

    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        merchant: Merchant,
        orderId: String?,
        errorTitle: String?,
        errorMessage: String?,
        router: WeakRouter<HomePayRoute>
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.merchant = merchant
        self.router = router
        self.orderId.onNext(orderId)
        self.errorTitle.onNext(errorTitle)
        self.errorMessage.onNext(errorMessage)
    }

    func transform(input: Input) -> Output {
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        var routeState: Driver<PayStatusState> = .just(.wait)
        
        let activeState: Driver<PayStatusState> = Driver
            .combineLatest(
                errorTitle.asDriver(onErrorJustReturn: nil),
                errorMessage.asDriver(onErrorJustReturn: nil),
                isSuccessPay.asDriver(onErrorJustReturn: false),
                routeState
            )
            .map { args -> PayStatusState in
                let (errorTitle, errorMessage, isSuccess, currentState) = args
                
                if (errorTitle != nil) || (errorMessage != nil) {
                    return .error(title: errorTitle, message: errorMessage)
                }
                if isSuccess {
                    return .success(title: "Оплачено", message: "Ваш баланс пополнен")
                }
                return currentState
            }
        
        input.closeButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .combineLatest(
                errorTitle.asDriver(onErrorJustReturn: nil),
                errorMessage.asDriver(onErrorJustReturn: nil),
                orderId.asDriver(onErrorJustReturn: nil)
            )
            .flatMapLatest { [weak self] args -> Driver<CheckPayResponseData?> in
                let (title, message, orderId) = args
                
                guard let self = self, let orderId = orderId, title == nil, message == nil else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .checkPay(merchant: self.merchant, orderId: orderId)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        return response
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] check in
                    var message: String = {
                        switch check.comment {
                        case "3d_secure_failed":
                            return " (ошибка 3ds)"
                        case "card_expired":
                            return " (срок действия карты истек)"
                        case "insufficient_funds":
                            return " (недостаточно средств)"
                        case "invalid_card_number":
                            return " (неправильно указан номер карты)"
                        default:
                            guard let comment = check.comment else {
                                return ""
                            }
                            return " (" + comment + ")"
                        }
                    }()
                    switch check.status {
                    case 0, 1:
                        break
                    case 2:
                        self?.isSuccessPay.onNext(true)
                    case 3:
                        self?.errorTitle.onNext("Отмена платежа")
                        self?.errorMessage.onNext("Ваш платеж отменён\(message)")
                    default:
                        self?.errorTitle.onNext("Ошибка оплаты")
                        self?.errorMessage.onNext("При выполнении оплаты произошла ошибка\(message)")
                    }
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.paymentCompleted)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(orderId.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] notification, orderId in
                    guard let self = self,
                          let orderId = orderId,
                          let userInfo = notification.userInfo,
                          let payOrderId = userInfo["orderId"] as? String,
                          let status = userInfo["status"] as? String,
                          orderId == payOrderId else {
                        return
                    }
                    let comment: String? = userInfo["comment"] as? String
                    var message: String = {
                        switch comment {
                        case "3d_secure_failed":
                            return " (ошибка 3ds)"
                        case "card_expired":
                            return " (срок действия карты истек)"
                        case "insufficient_funds":
                            return " (недостаточно средств)"
                        case "invalid_card_number":
                            return " (неправильно указан номер карты)"
                        default:
                            guard let commentInfo = comment else {
                                return ""
                            }
                            return " (" + commentInfo + ")"
                        }
                    }()
                    switch Int(status) {
                    case 0, 1:
                        break
                    case 2:
                        self.errorTitle.onNext(nil)
                        self.errorMessage.onNext(nil)
                        self.isSuccessPay.onNext(true)
                    case 3:
                        self.isSuccessPay.onNext(false)
                        self.errorTitle.onNext("Отмена платежа")
                        self.errorMessage.onNext("Ваш платеж отменён\(message)")
                    default:
                        self.isSuccessPay.onNext(false)
                        self.errorTitle.onNext("Ошибка оплаты")
                        self.errorMessage.onNext("При выполнении оплаты произошла ошибка\(message)")
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            activeState: activeState.asDriver()
        )
    }
}

extension PayStatusPopupViewModel {
    
    struct Input {
        let closeButtonTapped: Driver<Void>
    }
    
    struct Output {
        let activeState: Driver<PayStatusState>
    }
}
// swiftlint:enable function_body_length cyclomatic_complexity
