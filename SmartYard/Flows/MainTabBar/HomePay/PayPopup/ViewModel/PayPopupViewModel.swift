//
//  PayPopupViewModel.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 28.06.2024.
//  Copyright © 2024 Layka. All rights reserved.
//
// swiftlint:disable function_body_length cyclomatic_complexity type_body_length large_tuple file_length

import Foundation
import RxSwift
import RxCocoa
import XCoordinator
import UIKit
import TinkoffASDKCore
import TinkoffASDKUI
#if canImport(YooKassaPayments)
    import YooKassaPayments
#endif

class PayPopupViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let clientId: String
    private let contract: String?
    private var router: WeakRouter<HomePayRoute>
    
    private let recommendedSum = BehaviorSubject<Double?>(value: nil)
    private let merchant = BehaviorSubject<Merchant?>(value: nil)
    private let savedEmail = BehaviorSubject<String?>(value: nil)
    private let savedCheckState = BehaviorSubject<Bool>(value: false)
    private let needCheckState = BehaviorSubject<Bool>(value: false)
    private let orderIdSubject = BehaviorSubject<String?>(value: nil)
    private let paytypes = PublishSubject<[PayTypeObject]>()
    private let payNextStep = BehaviorSubject<PayStepState?>(value: nil)
    private let isSaveCardEnabledSubject = BehaviorSubject<Bool?>(value: nil)
    private let isAutopayEnabledSubject = BehaviorSubject<Bool>(value: true)
    private let isCheckEmailEnabledSubject = BehaviorSubject<Bool>(value: false)
    private let payTypeCurrentSubject = BehaviorSubject<PayTypeObject?>(value: nil)
    private let limitDocSubject = BehaviorSubject<URL?>(value: nil)
    private let serviceDocSubject = BehaviorSubject<URL?>(value: nil)

    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()

    private var pay: GetCardsResponseData?
    private var payoptions: PayContent? = nil
    private var isTBank: Bool = false // временное отключеник оплаты через СБП Т-Банк

    private let contractNumber: BehaviorSubject<String?>
    
    #if canImport(YooKassaPayments)
    private var tokenizationVC: (UIViewController & TokenizationModuleInput)? = nil
    #endif
    
    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        clientId: String,
        contractNumber: String?,
        router: WeakRouter<HomePayRoute>
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.clientId = clientId
        self.contract = contractNumber
        self.contractNumber = BehaviorSubject<String?>(value: contractNumber)
        self.router = router
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func alert(title: String, message: String?) {
        guard let pay = payoptions else {
            return
        }
        self.router.trigger(.payStatusPopup(merchant: pay.merchant, orderId: nil, errorTitle: title, errorMessage: message))
    }
    
    func checkPayment() {
        needCheckState.onNext(true)
    }
    
    func tokenizationModule(_ token: String, module: UIViewController) {
        guard let pay = payoptions, let contractName = pay.contractName, let description = pay.description, let check = pay.check else {
            return
        }
        let savecard: Bool = {
            guard let isSavecard = pay.isSavecard else {
                return false
            }
            return isSavecard
        }()
        apiWrapper.yooKassaNewPay(
            merchant: pay.merchant,
            paymentToken: token,
            contractName: contractName,
            summa: pay.summa,
            description: description,
            check: check,
            isAutopay: pay.isAutopay,
            isCardSave: savecard,
            email: pay.email
        )
        .trackError(errorTracker)
        .trackActivity(activityTracker)
        .asDriverOnErrorJustComplete()
        .ignoreNil()
        .drive(
            onNext: { [weak self] response in
                guard let self = self, let vc = self.tokenizationVC else {
                    return
                }
                
                var message: String = {
                    switch response.comment {
                    case "3d_secure_failed":
                        return " (ошибка 3ds)"
                    case "card_expired":
                        return " (срок действия карты истек)"
                    case "insufficient_funds":
                        return " (недостаточно средств)"
                    case "invalid_card_number":
                        return " (неправильно указан номер карты)"
                    default:
                        guard let comment = response.comment else {
                            return ""
                        }
                        return " ("+comment+")"
                    }
                }()

                switch response.status {
                case 0, 1, 2:
                    guard let confirmationUrl = response.confirmationUrl else {
                        module.dismiss(animated: true) {
                            self.router.trigger(.payStatusPopup(merchant: pay.merchant, orderId: response.orderId, errorTitle: nil, errorMessage: nil))
                        }
                        return
                    }
                    self.orderIdSubject.onNext(response.orderId)
                    vc.startConfirmationProcess(confirmationUrl: confirmationUrl, paymentMethodType: .bankCard)
                case 3:
                    module.dismiss(animated: true) {
                        self.router.trigger(.payStatusPopup(merchant: pay.merchant, orderId: nil, errorTitle: "Отмена платежа", errorMessage: "Платеж отменён банком\(message)"))
                    }
                default:
                    module.dismiss(animated: true) {
                        self.router.trigger(.payStatusPopup(merchant: pay.merchant, orderId: nil, errorTitle: "Ошибка оплаты", errorMessage: "При выполнении оплаты произошла ошибка\(message)"))
                    }
                }
            }
        )
        .disposed(by: disposeBag)
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

        let isPaySuccessTrigger = PublishSubject<Bool>()
        var routeState: Driver<Bool> = .just(true)
        let paymentActivityTracker = ActivityTracker()

        let isAbleToProceedRequest = Driver
            .combineLatest(
                input.inputSumNumText,
                input.inputEmailText,
                isCheckEmailEnabledSubject.asDriver(onErrorJustReturn: false),
                payTypeCurrentSubject.asDriver(onErrorJustReturn: nil),
                paymentActivityTracker,
                routeState
            )
            .map { args -> Bool in
                let (sumNumber, email, isCheckEmail, paytype, isPayActive, routeStatus) = args
                
                if isPayActive {
                    return false
                }
                
                guard let uSumNumber = sumNumber?.trimmed, (Double(uSumNumber.replacingOccurrences(of: ",", with: ".")) ?? 0 > 0) else {
                    return false
                }
                if let uPaytype = paytype, uPaytype.paymentWay == .SBP, (Double(uSumNumber.replacingOccurrences(of: ",", with: ".")) ?? 0 < 10) {
                    return false
                }
                                                            
                if isCheckEmail {
                    guard let uEmail = email?.trimmed, self.isValidEmail(uEmail) else {
                        return false
                    }
                }

                return routeStatus
            }
        
        Driver
            .combineLatest(
                needCheckState.asDriver(onErrorJustReturn: false),
                orderIdSubject.asDriver(onErrorJustReturn: nil)
            )
            .debounce(.milliseconds(150))
            .drive(
                onNext: { [weak self] args in
                    let (needcheck, orderId) = args
                    guard let self = self, needcheck, let orderId = orderId, let pay = self.payoptions else {
                        return
                    }
                    self.router.trigger(.payStatusPopup(merchant: pay.merchant, orderId: orderId, errorTitle: nil, errorMessage: nil))
                }
            )
            .disposed(by: disposeBag)

        let getCardActivityTracker = ActivityTracker()
        
        Driver
            .merge(
                contractNumber.asDriver(onErrorJustReturn: nil),
                .just(nil)
            )
            .ignoreNil()
            .flatMapLatest { [weak self] contractNumber -> Driver<(String, GetCardsResponseData?)?> in
                guard let self = self else {
                    return .empty()
                }
                return self.apiWrapper.getCards(contractName: contractNumber)
                    .trackError(errorTracker)
                    .trackActivity(getCardActivityTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        return (contractNumber, response)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .flatMapLatest { [weak self] args -> Driver<(GetCardsResponseData?, [PayTypeObject])> in
                let (cNumber, prepare) = args
                
                guard let self = self, let prepare = prepare else {
                    return .just((nil, []))
                }
                
                var payTypes: [PayTypeObject] = []
                var number: Int = 0
                if #available(iOS 13.0, *), self.isTBank {
                    let paySBPObject = PayTypeObject(
                        number: 0,
                        bindingId: nil,
                        paymentWay: .SBP,
                        paymentSystem: .SBP,
                        label: "Система быстрых платежей",
                        isCardActions: false,
                        isSelected: true
                    )
                    payTypes.append(paySBPObject)
                    number += 1
                    self.payTypeCurrentSubject.onNext(paySBPObject)
                    self.isAutopayEnabledSubject.onNext(false)
                    self.isSaveCardEnabledSubject.onNext(nil)
                }
                
                if !prepare.cards.isEmpty {
                    payTypes += prepare.cards.enumerated().map { offset, element in
                        let payObject = PayTypeObject(
                            number: offset + number,
                            bindingId: element.bindingId,
                            paymentWay: element.paymentWay ?? .CARD,
                            paymentSystem: element.paymentSystem ?? .OTHER,
                            label: (element.paymentSystem?.label ?? "*") + (element.displayLabel ?? ""),
                            isCardActions: element.paymentWay == .CARD ? true : false,
                            isSelected: (offset + number) == .zero
                        )
                        if (offset + number) == .zero {
                            self.payTypeCurrentSubject.onNext(payObject)
                            self.isAutopayEnabledSubject.onNext(element.autopay)
                            self.isSaveCardEnabledSubject.onNext(nil)
                        }
                        return payObject
                    }
                }
                
                let payNewObject = PayTypeObject(
                    number: prepare.cards.count + number,
                    bindingId: nil,
                    paymentWay: .NEW,
                    paymentSystem: .NEW,
                    label: "Новая банковская карта",
                    isCardActions: false,
                    isSelected: (prepare.cards.count + number) == .zero
                )
                payTypes.append(payNewObject)
                if (prepare.cards.count + number) == .zero {
                    self.payTypeCurrentSubject.onNext(payNewObject)
                    self.isAutopayEnabledSubject.onNext(true)
                    self.isSaveCardEnabledSubject.onNext(true)
                }

                return .just((prepare, payTypes))
            }
            .drive(
                onNext: { [weak self] args in
                    let (pay, paytypes) = args
                    
                    guard let pay = pay else {
                        return
                    }
                    self?.pay = pay
                    self?.recommendedSum.onNext(pay.payAdvice)
                    self?.savedEmail.onNext(pay.email)
                    self?.isCheckEmailEnabledSubject.onNext(pay.check == .email)
                    self?.merchant.onNext(pay.merchant)
                    self?.paytypes.onNext(paytypes)
                    
                    if let docLimit = pay.docLimit, let limitUrl = URL(string: docLimit) {
                        self?.limitDocSubject.onNext(limitUrl)
                    }
                    if let docTerms = pay.docTerms, let termsUrl = URL(string: docTerms) {
                        self?.serviceDocSubject.onNext(termsUrl)
                    }
                }
            )
            .disposed(by: disposeBag)

        input.limitDocShowTrigger
            .withLatestFrom(limitDocSubject.asDriver(onErrorJustReturn: nil))
            .drive(
                onNext: { [weak self] docUrl in
                    guard let docUrl = docUrl else {
                        return
                    }
                    self?.router.trigger(.pdfView(url: docUrl))
                }
            )
            .disposed(by: disposeBag)
        
        input.serviceDocShowTrigger
            .withLatestFrom(serviceDocSubject.asDriver(onErrorJustReturn: nil))
            .drive(
                onNext: { [weak self] docUrl in
                    guard let docUrl = docUrl else {
                        return
                    }
                    self?.router.trigger(.pdfView(url: docUrl))
                }
            )
            .disposed(by: disposeBag)
        
        input.cardButtonTapped
            .withLatestFrom(isAbleToProceedRequest)
            .isTrue()
            .withLatestFrom(payTypeCurrentSubject.asDriver(onErrorJustReturn: nil))
            .flatMapLatest { [weak self] paytype -> Driver<(PaymentWays, String?)?> in
                self?.payoptions = nil
                guard let uPayType = paytype else {
                    return .just(nil)
                }
                return .just((uPayType.paymentWay, uPayType.bindingId))
            }
            .ignoreNil()
            .withLatestFrom(input.inputSumNumText.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { args -> Driver<(PaymentWays, String?, Double)?> in
                let (paytype, summa) = args
                let (payway, bindingId) = paytype
                guard let uSum = summa?.trimmed,
                      let sumDouble =  Double(uSum.replacingOccurrences(of: ",", with: ".")),
                      sumDouble > 0 else {
                    return .just(nil)
                }
                return .just((payway, bindingId, sumDouble))
            }
            .ignoreNil()
            .withLatestFrom(merchant.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(PaymentWays, PayContent, String?)?> in
                let (pay, merchant) = args
                let (payway, bindingId, summa) = pay
                
                guard let self = self, let merchant = merchant else {
                    return .just(nil)
                }

                return .just((payway, PayContent(merchant: merchant, summa: summa), bindingId))
            }
            .ignoreNil()
            .withLatestFrom(isAutopayEnabledSubject.asDriverOnErrorJustComplete()) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(PaymentWays, PayContent, String?)?> in
                let (pay, isautopay) = args
                let (payway, paycontent, bindingId) = pay
                
                guard let self = self else {
                    return .just(nil)
                }

                return .just((payway, PayContent(merchant: paycontent.merchant, summa: paycontent.summa, isAutopay: isautopay), bindingId))
            }
            .ignoreNil()
            .withLatestFrom(isSaveCardEnabledSubject.asDriverOnErrorJustComplete()) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(PaymentWays, PayContent, String?)?> in
                let (pay, savecard) = args
                let (payway, paycontent, bindingId) = pay
                
                guard let self = self else {
                    return .just(nil)
                }
                guard let issavecard = savecard else {
                    return .just((payway, paycontent, bindingId))
                }
                let uPaycontent = PayContent(
                    merchant: paycontent.merchant,
                    summa: paycontent.summa,
                    isAutopay: issavecard ? paycontent.isAutopay : false,
                    isSaveCard: issavecard
                )
                return .just((payway, uPaycontent, bindingId))
            }
            .ignoreNil()
            .withLatestFrom(isCheckEmailEnabledSubject.asDriver(onErrorJustReturn: false)) { ($0, $1) }
            .withLatestFrom(input.inputEmailText.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args, email -> Driver<(PaymentWays, PayContent, CreateSBPOrderResponseData?, String?)?> in
                let (pay, check) = args
                let (payway, paycontent, bindingId) = pay
                
                guard let self = self, let contractName = contract else {
                    return .just(nil)
                }
                let description = "Оплата по договору №\(contractName)"
                let checktype: CheckSendType = check ? .email : .push
                var emailtext: String? = {
                    guard let uEmail = email, self.isValidEmail(uEmail.trimmed) else {
                        return nil
                    }
                    return uEmail.trimmed
                }()
                let paycontentfull = PayContent(
                    merchant: paycontent.merchant,
                    summa: paycontent.summa,
                    isAutopay: paycontent.isAutopay,
                    isSaveCard: paycontent.isSavecard,
                    bindingId: bindingId,
                    contractName: contractName,
                    description: description,
                    check: checktype,
                    email: emailtext
                )
                switch payway {
                case .CARD:
                    guard let bindingId = bindingId else {
                        return .just(nil)
                    }
                    return self.apiWrapper.autoPay(
                            merchant: paycontent.merchant,
                            contractName: contractName,
                            summa: paycontent.summa,
                            description: description,
                            bindingId: bindingId,
                            check: checktype,
                            email: emailtext
                        )
                        .trackError(errorTracker)
                        .trackActivity(paymentActivityTracker)
                        .map {
                            guard let response = $0 else {
                                return (payway, paycontentfull, nil, nil)
                            }
                            return (payway, paycontentfull, nil, response.orderId)
                        }
                        .asDriverOnErrorJustComplete()
                case .SBP:
                    return self.apiWrapper.createNewSBPPay(
                            merchant: paycontent.merchant,
                            contractName: contractName,
                            summa: paycontent.summa,
                            description: description,
                            check: checktype,
                            email: emailtext
                        )
                        .trackError(errorTracker)
                        .trackActivity(paymentActivityTracker)
                        .map {
                            guard let response = $0 else {
                                return (payway, paycontentfull, nil, nil)
                            }
                            return (payway, paycontentfull, response, nil)
                        }
                        .asDriverOnErrorJustComplete()
                default:
                    break
                }
                return .just((payway, paycontentfull, nil, nil))
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    let (payway, paycontent, spborder, orderId) = args

                    guard let self = self else {
                        return
                    }

                    switch payway {
                    case .CARD:
                        self.router.trigger(.dismiss)
                        guard let orderId = orderId else {
                            self.router.trigger(.payStatusPopup(merchant: paycontent.merchant, orderId: nil, errorTitle: "Ошибка", errorMessage: "Платеж не проведен"))
                            return
                        }
                        self.router.trigger(.payStatusPopup(merchant: paycontent.merchant, orderId: orderId, errorTitle: nil, errorMessage: nil))
                    case .NEW:
                        self.payYooNewCard(vc: input.vc, pay: paycontent)
                    case .SBP:
                        guard let order = spborder else {
                            return
                        }
                        self.paySBP(vc: input.vc, pay: paycontent, orderId: String(order.id))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.autopayTrigger
            .withLatestFrom(isSaveCardEnabledSubject.asDriver(onErrorJustReturn: nil))
            .flatMapLatest { [weak self] issavecard -> Driver<Bool> in
                guard let issavecard = issavecard else {
                    return .just(true)
                }
                return .just(issavecard)
            }
            .isTrue()
            .withLatestFrom(isAutopayEnabledSubject.asDriver(onErrorJustReturn: true))
            .withLatestFrom(merchant.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .withLatestFrom(payTypeCurrentSubject.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<Bool?> in
                let (merchtype, paytype) = args
                let (isAutopay, merchant) = merchtype
                
                guard let self = self, let merchant = merchant else {
                    return .empty()
                }
                guard let upaytype = paytype, upaytype.paymentWay == .CARD, let bindingId = upaytype.bindingId else {
                    return .just(!isAutopay)
                }
                if isAutopay {
                    return self.apiWrapper
                        .removeAutopay(merchant: merchant, bindingId: bindingId)
                        .trackError(errorTracker)
                        .trackActivity(activityTracker)
                        .map {
                            guard let response = $0 else {
                                return nil
                            }
                            return false
                        }
                        .asDriver(onErrorJustReturn: nil)
                } else {
                    return self.apiWrapper
                        .addAutopay(merchant: merchant, bindingId: bindingId)
                        .trackError(errorTracker)
                        .trackActivity(activityTracker)
                        .map {
                            guard let response = $0 else {
                                return nil
                            }
                            return true
                        }
                        .asDriver(onErrorJustReturn: nil)
                }
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] state in
                    self?.isAutopayEnabledSubject.onNext(state)
                }
            )
            .disposed(by: disposeBag)

        input.checkEmailTrigger
            .withLatestFrom(isCheckEmailEnabledSubject.asDriver(onErrorJustReturn: false))
            .drive(
                onNext: { [weak self] state in
                    self?.isCheckEmailEnabledSubject.onNext(!state)
                }
            )
            .disposed(by: disposeBag)
        
        input.saveCardTrigger
            .withLatestFrom(isSaveCardEnabledSubject.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .drive(
                onNext: { [weak self] state in
                    self?.isSaveCardEnabledSubject.onNext(!state)
                }
            )
            .disposed(by: disposeBag)

        input.cardEditSettingsTrigger
            .withLatestFrom(paytypes.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .withLatestFrom(merchant.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (hc, merchant) = args
                    let (height, cards) = hc
                    guard let height = height, !cards.isEmpty, let merchant = merchant else {
                        return
                    }
                    self?.router.trigger(.selectTypePopup(cards: cards, height: height, merchant: merchant))
                }
            )
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.refreshPayCard)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(contractNumber.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] notification, contract -> Driver<(Int, GetCardsResponseData?)?> in
                guard let self = self, let selected = notification.object as? Int, let contractNumber = contract else {
                    return .empty()
                }
                return self.apiWrapper.getCards(contractName: contractNumber)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        return (selected, response)
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .flatMapLatest { [weak self] args -> Driver<[PayTypeObject]> in
                let (sNumber, prepare) = args
                
                guard let self = self, let prepare = prepare else {
                    return .just([])
                }
                
                var payTypes: [PayTypeObject] = []
                var number: Int = 0
                if #available(iOS 13.0, *), self.isTBank {
                    let paySBPObject = PayTypeObject(
                        number: number,
                        bindingId: nil,
                        paymentWay: .SBP,
                        paymentSystem: .SBP,
                        label: "Система быстрых платежей",
                        isCardActions: false,
                        isSelected: sNumber == 0
                    )
                    payTypes.append(paySBPObject)
                    number += 1
                    if sNumber == 0 {
                        self.payTypeCurrentSubject.onNext(paySBPObject)
                        self.isAutopayEnabledSubject.onNext(false)
                        self.isSaveCardEnabledSubject.onNext(nil)
                    }
                }
                
                if !prepare.cards.isEmpty {
                    payTypes += prepare.cards.enumerated().map { offset, element in
                        let payObject = PayTypeObject(
                            number: offset + number,
                            bindingId: element.bindingId,
                            paymentWay: element.paymentWay ?? .CARD,
                            paymentSystem: element.paymentSystem ?? .OTHER,
                            label: (element.paymentSystem?.label ?? "*") + (element.displayLabel ?? ""),
                            isCardActions: element.paymentWay == .CARD ? true : false,
                            isSelected: (offset + number) == sNumber
                        )
                        if (offset + number) == sNumber {
                            self.payTypeCurrentSubject.onNext(payObject)
                            self.isAutopayEnabledSubject.onNext(element.autopay)
                            self.isSaveCardEnabledSubject.onNext(nil)
                        }
                        return payObject
                    }
                }
                let payNewObject = PayTypeObject(
                    number: prepare.cards.count + number,
                    bindingId: nil,
                    paymentWay: .NEW,
                    paymentSystem: .NEW,
                    label: "Новая банковская карта",
                    isCardActions: true,
                    isSelected: (prepare.cards.count + number) == sNumber
                )
                payTypes.append(payNewObject)
                if (prepare.cards.count + number) == sNumber {
                    self.payTypeCurrentSubject.onNext(payNewObject)
                    self.isAutopayEnabledSubject.onNext(true)
                    self.isSaveCardEnabledSubject.onNext(true)
                }

                return .just(payTypes)
            }
            .drive(
                onNext: { [weak self] paytypes in
                    
                    self?.paytypes.onNext(paytypes)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isPaySuccessTrigger: isPaySuccessTrigger.asDriver(onErrorJustReturn: false),
            recommendedSum: recommendedSum.asDriver(onErrorJustReturn: nil),
            savedEmail: savedEmail.asDriver(onErrorJustReturn: nil), 
            isSaveCardEnable: isSaveCardEnabledSubject.asDriver(onErrorJustReturn: nil),
            isCheckEmailEnable: isCheckEmailEnabledSubject.asDriver(onErrorJustReturn: false),
            isAutopayEnable: isAutopayEnabledSubject.asDriver(onErrorJustReturn: true),
            payTypes: paytypes.asDriver(onErrorJustReturn: []),
            contractNumber: contractNumber.asDriver(onErrorJustReturn: nil),
            isAbleToProceedRequest: isAbleToProceedRequest.asDriver(),
            payNextStep: payNextStep.asDriverOnErrorJustComplete(),
            isCardLoaded: getCardActivityTracker.asDriver(),
            isPaymentActive: paymentActivityTracker.asDriver()
        )
    }
    
    private func paySBP(vc: UIViewController, pay: PayContent, orderId: String) {
        
        let credential = AcquiringSdkCredential(terminalKey: Constants.tbankAPITerminalKey(pay.merchant), publicKey: Constants.tbankAPIPublicKey(pay.merchant))
        let coreSDKConfiguration = AcquiringSdkConfiguration(
            credential: credential,
            server: .prod,
            logger: Logger()
        )
        let uiSDKConfiguration = UISDKConfiguration(paymentStatusRetriesCount: 200)
        let orderOptions = OrderOptions(orderId: orderId, amount: Int64(pay.summa * 100), description: pay.description)
        let paymentOptions = PaymentOptions(orderOptions: orderOptions)
        
        do {
            let sdk = try AcquiringUISDK(coreSDKConfiguration: coreSDKConfiguration, uiSDKConfiguration: uiSDKConfiguration)
            let paymentFlow: PaymentFlow = .full(paymentOptions: paymentOptions)
            sdk.presentSBPBanksList(on: vc, paymentFlow: paymentFlow) { [weak self] result in
                switch result {
                case let .succeeded(payment):
                    print(payment)
                    guard let self = self else {
                        return
                    }
                    self.apiWrapper.updateSBPPay(
                        merchant: pay.merchant,
                        id: orderId,
                        status: payment.paymentStatus.hashValue,
                        orderId: payment.orderId
                    )
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
                    .ignoreNil()
                    .drive(
                        onNext: { result in
                            print(result.success)
                            NotificationCenter.default.post(name: .reconfigureGestures, object: nil)
                        }
                    )
                    .disposed(by: disposeBag)
                case let .failed(error):
                    guard let error = error as? APIError else {
                        return
                    }
                    switch error {
                    case let .failure(failure):
                        self?.router.trigger(.alert(title: "Ошибка " + failure.errorCode.string, message: failure.errorMessage))
                    default:
                        break
                    }
                case let .cancelled(info):
                    print("Cancelled")
                    guard let self = self, let payment = info else {
                        return
                    }
                    print(payment)
                    self.apiWrapper.updateSBPPay(
                        merchant: pay.merchant,
                        id: orderId,
                        status: payment.paymentStatus.hashValue,
                        orderId: payment.orderId
                    )
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
                    .ignoreNil()
                    .drive(
                        onNext: { result in
                            print(result.success)
                            NotificationCenter.default.post(name: .reconfigureGestures, object: nil)
                            NotificationCenter.default.post(name: .reconfigureGestures, object: nil)
                        }
                    )
                    .disposed(by: disposeBag)
                }
            }
        } catch {
            print(error)
        }

    }
    
    private func payYooNewCard(vc: UIViewController, pay: PayContent) {
        guard #available(iOS 14.0, *), let description = pay.description else {
            return
        }
        self.payoptions = pay
        self.needCheckState.onNext(false)
        self.orderIdSubject.onNext(nil)
        
        var customerId: String? = {
            guard let phone = self.accessService.clientPhoneNumber else {
                return nil
            }
            return "8" + phone
        }()
        
        let savePayment: Bool = {
            guard let isSavecard = pay.isSavecard else {
                return false
            }
            return isSavecard
        }()
        let amount = Amount(value: Decimal(pay.summa), currency: .rub)
        let clientApplicationKey = Constants.yoomoneyKey(pay.merchant)
        let clientShopId = Constants.yoomoneyShopId(pay.merchant)
        var paymentMethodTypes: PaymentMethodTypes = [.bankCard]
        let tokenizationSettings = TokenizationSettings(paymentMethodTypes: paymentMethodTypes)
        let customizationSettings = CustomizationSettings(mainScheme: UIColor.SmartYard.blue, showYooKassaLogo: false)
        let tokenizationModuleInputData = TokenizationModuleInputData(
            clientApplicationKey: clientApplicationKey,
            shopName: "Centra",
            shopId: clientShopId,
            purchaseDescription: description,
            amount: amount,
            tokenizationSettings: tokenizationSettings,
            customizationSettings: customizationSettings,
            savePaymentMethod: savePayment ? .on : .off,
            customerId: savePayment ? customerId : nil
        )
        let inputData: TokenizationFlow = .tokenization(tokenizationModuleInputData)
        
        guard let vcOut = vc as? TokenizationModuleOutput else {
            return
        }
        tokenizationVC = TokenizationAssembly.makeModule(inputData: inputData, moduleOutput: vcOut)
        guard let tokenizationVC = tokenizationVC else {
            return
        }
        vc.present(tokenizationVC, animated: true)
    }
}

@available(iOS 14.0, *)
extension PayPopupViewController: TokenizationModuleOutput {
    func didFinish(on module: any YooKassaPayments.TokenizationModuleInput, with error: YooKassaPayments.YooKassaPaymentsError?) {
        guard let error = error else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.dismiss(animated: true)
            }
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.dismiss(animated: true)
        }
    }
    
    func didFinishConfirmation(paymentMethodType: YooKassaPayments.PaymentMethodType) {
        print("FINISH CONFIRM")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            switch paymentMethodType {
            case .bankCard:
                self.dismiss(animated: true) {
                    self.viewModel.checkPayment()
                }
            default:
                self.dismiss(animated: true)
            }
        }
    }
    
    func didFailConfirmation(error: YooKassaPayments.YooKassaPaymentsError?) {
        print("FAIL CONFIRM")
        guard let error = error else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.dismiss(animated: true)
            }
            return
        }
        print("FAIL CONFIRM", error)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.dismiss(animated: true)
            switch error {
            case .paymentMethodNotFound:
                self.viewModel.alert(title: "Метод оплаты не найден", message: nil)
            case let .paymentConfirmation(error):
                self.viewModel.alert(title: "Ошибка оплаты", message: error.localizedDescription)
            }
        }
    }
    
    func tokenizationModule(_ module: any YooKassaPayments.TokenizationModuleInput, didTokenize token: YooKassaPayments.Tokens, paymentMethodType: YooKassaPayments.PaymentMethodType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            switch paymentMethodType {
            case .bankCard:
                self.viewModel.tokenizationModule(token.paymentToken, module: self)
            default:
                self.dismiss(animated: true)
            }
        }
    }
}

extension PayPopupViewModel {
    
    struct Input {
        let inputSumNumText: Driver<String?>
        let inputEmailText: Driver<String?>
        let saveCardTrigger: Driver<Void>
        let autopayTrigger: Driver<Void>
        let checkEmailTrigger: Driver<Void>
        let cardEditSettingsTrigger: Driver<CGFloat?>
        let cardButtonTapped: Driver<Void>
        let animatedHeight: Driver<CGFloat>
        let limitDocShowTrigger: Driver<String>
        let serviceDocShowTrigger: Driver<String>
        let vc: UIViewController
    }
    
    struct Output {
        let isPaySuccessTrigger: Driver<Bool>
        let recommendedSum: Driver<Double?>
        let savedEmail: Driver<String?>
        let isSaveCardEnable: Driver<Bool?>
        let isCheckEmailEnable: Driver<Bool>
        let isAutopayEnable: Driver<Bool>
        let payTypes: Driver<[PayTypeObject]>
        let contractNumber: Driver<String?>
        let isAbleToProceedRequest: Driver<Bool>
        let payNextStep: Driver<PayStepState?>
        let isCardLoaded: Driver<Bool>
        let isPaymentActive: Driver<Bool>
    }
    
    struct PayContent {
        let merchant: Merchant
        let summa: Double
        let isAutopay: Bool
        let isSavecard: Bool?
        let bindingId: String?
        let contractName: String?
        let description: String?
        let check: CheckSendType?
        let email: String?
        
        init(
            merchant: Merchant,
            summa: Double,
            isAutopay: Bool = false,
            isSaveCard: Bool? = nil,
            bindingId: String? = nil,
            contractName: String? = nil, 
            description: String? = nil,
            check: CheckSendType? = nil,
            email: String? = nil
        ) {
            self.merchant = merchant
            self.summa = summa
            self.isAutopay = isAutopay
            self.isSavecard = isSaveCard
            self.bindingId = bindingId
            self.contractName = contractName
            self.description = description
            self.check = check
            self.email = email
        }
    }
}
// swiftlint:enable function_body_length cyclomatic_complexity type_body_length large_tuple file_length
