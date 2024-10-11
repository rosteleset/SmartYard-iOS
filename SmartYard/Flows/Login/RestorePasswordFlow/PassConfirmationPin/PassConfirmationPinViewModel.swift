//
//  PassConfirmationPinViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 23.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class PassConfirmationPinViewModel: BaseViewModel {
    
//    private let router: WeakRouter<HomeRoute>?
    private let router: WeakRouter<MyYardRoute>?
    private let routerhomepay: WeakRouter<HomePayRoute>?
    private let routerweb: WeakRouter<HomeWebRoute>?
//    private let routerintercom: WeakRouter<IntercomWebRoute>?

    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService

    private let selectedRestoreMethod: RestoreMethod
    private let contractNum: String
    
    init(
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        routerweb: WeakRouter<HomeWebRoute>,
        contractNum: String,
        selectedRestoreMethod: RestoreMethod
    ) {
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = nil
        self.routerweb = routerweb
        self.routerhomepay = nil
        self.selectedRestoreMethod = selectedRestoreMethod
        self.contractNum = contractNum
    }
    
    init(
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        routerhomepay: WeakRouter<HomePayRoute>,
        contractNum: String,
        selectedRestoreMethod: RestoreMethod
    ) {
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = nil
        self.routerweb = nil
        self.routerhomepay = routerhomepay
        self.selectedRestoreMethod = selectedRestoreMethod
        self.contractNum = contractNum
    }
    
    init(
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<MyYardRoute>,
        contractNum: String,
        selectedRestoreMethod: RestoreMethod
    ) {
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
        self.routerweb = nil
        self.routerhomepay = nil
        self.selectedRestoreMethod = selectedRestoreMethod
        self.contractNum = contractNum
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let isPinCorrect = BehaviorSubject<Bool>(value: true)
        let prepareTransitionTrigger = PublishSubject<Void>()
        
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
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 403:
                        isPinCorrect.onNext(false)
                        
                    default:
                        self?.router?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                        self?.routerweb?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                        self?.routerhomepay?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.inputPinText
            .distinctUntilChanged()
            .do(
                onNext: { _ in
                    isPinCorrect.onNext(true)
                }
            )
            .filter { $0.count == Constants.pinLength }
            .flatMapLatest { [weak self] smsCode -> Driver<RestoreRequestResponseData?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                return self.apiWrapper.restore(
                        contractNum: self.contractNum,
                        contactId: nil,
                        code: smsCode
                    )
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { _ in
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }

                    let okAction = UIAlertAction(title: "Ок", style: .default) { [weak self] _ in
                        self?.router?.trigger(.main)
                        self?.routerweb?.trigger(.main)
                        self?.routerhomepay?.trigger(.main)
                    }
                    
                    let passDestination = self.selectedRestoreMethod.contact.contains("@") ? "email" : "телефон"
                    let dialogText = "Пароль от указанной записи отправлен на указанный \(passDestination)"
                    
                    self.router?.trigger(.dialog(title: "", message: dialogText, actions: [okAction]))
                    self.routerweb?.trigger(.dialog(title: "", message: dialogText, actions: [okAction]))
                    self.routerhomepay?.trigger(.dialog(title: "", message: dialogText, actions: [okAction]))
                }
            )
            .disposed(by: disposeBag)
        
        input.sendCodeAgainButtonTapped
            .flatMapLatest { [weak self] _ -> Driver<RestoreRequestResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.restore(
                        contractNum: self.contractNum,
                        contactId: self.selectedRestoreMethod.contactId,
                        code: nil
                    )
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .drive()
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
            isPinCorrect: isPinCorrect.asDriverOnErrorJustComplete(),
            restoreMethod: .just(selectedRestoreMethod),
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension PassConfirmationPinViewModel {
    
    struct Input {
        let inputPinText: Driver<String>
        let sendCodeAgainButtonTapped: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let isPinCorrect: Driver<Bool>
        let restoreMethod: Driver<RestoreMethod>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
// swiftlint:enable function_body_length
