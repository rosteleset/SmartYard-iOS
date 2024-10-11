//
//  AuthByContractNumViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class AuthByContractNumViewModel: BaseViewModel {
    
//    private let router: WeakRouter<HomeRoute>?
    private let router: WeakRouter<MyYardRoute>?
    private let routerhomepay: WeakRouter<HomePayRoute>?
    private let routerweb: WeakRouter<HomeWebRoute>?
//    private let routerintercom: WeakRouter<IntercomWebRoute>?

    private let issueService: IssueService
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService

    init(
        routerweb: WeakRouter<HomeWebRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.routerweb = routerweb
        self.router = nil
        self.routerhomepay = nil
//        self.routerintercom = nil
        self.issueService = issueService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
    }
    
    init(
        router: WeakRouter<MyYardRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.router = router
        self.routerweb = nil
        self.routerhomepay = nil
//        self.routerintercom = nil
        self.issueService = issueService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
    }
    
    init(
        routerhomepay: WeakRouter<HomePayRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.router = nil
        self.routerweb = nil
        self.routerhomepay = routerhomepay
//        self.routerintercom = nil
        self.issueService = issueService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: activityTracker,
                    errorTracker: errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    self?.router?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    self?.routerweb?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    self?.routerhomepay?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
     
        input.forgetPassTapped
            .withLatestFrom(input.inputContractNumText.asDriver(onErrorJustReturn: nil))
            .drive(
                onNext: { [weak self] contractNum in
                    self?.router?.trigger(.restorePassword(contractNum: contractNum))
                    self?.routerweb?.trigger(.restorePassword(contractNum: contractNum))
                    self?.routerhomepay?.trigger(.restorePassword(contractNum: contractNum))
                }
            )
            .disposed(by: disposeBag)
        
        let restoreContractDataSubject = PublishSubject<Void>()
        
        restoreContractDataSubject
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }

                return self.issueService.sendNothingRememberIssue()
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .drive()
            .disposed(by: disposeBag)
        
        input.forgetEverythingTapped
            .drive(
                onNext: { [weak self] in
                    let okAction = UIAlertAction(title: "Создать", style: .default) { _ in
                        restoreContractDataSubject.onNext(())
                    }
                    
                    let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
                    
                    self?.router?.trigger(
                        .dialog(
                            title: "Создать заявку на восстановление данных по договору?",
                            message: nil,
                            actions: [okAction, cancelAction]
                        )
                    )
                    self?.routerweb?.trigger(
                        .dialog(
                            title: "Создать заявку на восстановление данных по договору?",
                            message: nil,
                            actions: [okAction, cancelAction]
                        )
                    )
                    self?.routerhomepay?.trigger(
                        .dialog(
                            title: "Создать заявку на восстановление данных по договору?",
                            message: nil,
                            actions: [okAction, cancelAction]
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        input.noContractTapped
            .drive(
                onNext: { [weak self] in
                    self?.router?.trigger(.inputAddress)
                    self?.routerweb?.trigger(.inputAddress)
                    self?.routerhomepay?.trigger(.inputAddress)
                }
            )
            .disposed(by: disposeBag)
        
        let isAbleToProceed = Driver
            .combineLatest(
                input.inputContractNumText,
                input.inputPasswordNumText
            )
            .map { args -> Bool in
                let (contractNumber, password) = args
                
                guard let uContractNumber = contractNumber?.trimmed, !uContractNumber.isEmpty,
                    let uPassword = password?.trimmed, !uPassword.isEmpty else {
                    return false
                }
                
                return true
            }
        
        input.signInTapped
            .withLatestFrom(isAbleToProceed)
            .isTrue()
            .withLatestFrom(input.inputContractNumText.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(input.inputPasswordNumText.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(CheckOffertaRequestResponseData, String, String)?> in
                let (login, password) = args
                
                guard let self = self, let uLogin = login, let uPassword = password else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .checkOfferta(
                        login: uLogin.trimmed,
                        password: uPassword.trimmed
                    )
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        
                        return (response, uLogin.trimmed, uPassword.trimmed)
                    }
                    .asDriver(onErrorJustReturn: nil)
                
//                return self.apiWrapper
//                    .addMyPhone(
//                        login: uLogin.trimmed,
//                        password: uPassword.trimmed,
//                        comment: nil,
//                        useForNotifications: true
//                    )
//                    .trackActivity(activityTracker)
//                    .trackError(errorTracker)
//                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    let (offers, login, password) = args
                    
                    guard let self = self, !offers.isEmpty else {
                        self?.router?.trigger(.main)
                        self?.routerweb?.trigger(.main)
                        self?.routerhomepay?.trigger(.main)
                        NotificationCenter.default.post(name: .addressAdded, object: nil)
                        return
                    }
                    self.router?.trigger(.acceptOfferta(login: login, password: password, offers: offers))
                    self.routerweb?.trigger(.acceptOfferta(login: login, password: password, offers: offers))
                    self.routerhomepay?.trigger(.acceptOfferta(login: login, password: password, offers: offers))
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router?.trigger(.back)
                    self?.routerweb?.trigger(.back)
                    self?.routerhomepay?.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            isAbleToProceed: isAbleToProceed.asDriver()
        )
    }
    
}

extension AuthByContractNumViewModel {
    
    struct Input {
        let forgetPassTapped: Driver<Void>
        let forgetEverythingTapped: Driver<Void>
        let noContractTapped: Driver<Void>
        let signInTapped: Driver<Void>
        let backTrigger: Driver<Void>
        
        let inputContractNumText: Driver<String?>
        let inputPasswordNumText: Driver<String?>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let isAbleToProceed: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
