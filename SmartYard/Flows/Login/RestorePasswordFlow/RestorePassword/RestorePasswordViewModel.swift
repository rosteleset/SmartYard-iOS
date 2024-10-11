//
//  RestorePasswordViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class RestorePasswordViewModel: BaseViewModel {
    
//    private let router: WeakRouter<HomeRoute>?
    private let router: WeakRouter<MyYardRoute>?
    private let routerhomepay: WeakRouter<HomePayRoute>?
    private let routerweb: WeakRouter<HomeWebRoute>?
//    private let routerintercom: WeakRouter<IntercomWebRoute>?
    
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private let selectedRestoreMethod = BehaviorSubject<RestoreMethodCellModel?>(value: nil)
    private let restoreMethods = BehaviorSubject<[RestoreMethodCellModel]>(value: [])
    
    init(
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        routerweb: WeakRouter<HomeWebRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = nil
        self.routerweb = routerweb
        self.routerhomepay = nil
    }
    
    init(
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        routerhomepay: WeakRouter<HomePayRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = nil
        self.routerweb = nil
        self.routerhomepay = routerhomepay
    }
    
    init(
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<MyYardRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
        self.routerweb = nil
        self.routerhomepay = nil
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
                    let nsError = error as NSError
                    
                    switch nsError.code {
                    case 422, 404:
                        let message = "Введен неверный номер договора"
                        self?.router?.trigger(.alert(title: "Ошибка", message: message))
                        self?.routerweb?.trigger(.alert(title: "Ошибка", message: message))
                        self?.routerhomepay?.trigger(.alert(title: "Ошибка", message: message))

                    default:
                        self?.router?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                        self?.routerweb?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                        self?.routerhomepay?.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        let contractNum = input.inputContractNum
            .asDriver(onErrorJustReturn: nil)
            .do(
                onNext: { [weak self] _ in
                    self?.restoreMethods.onNext([])
                }
            )
        
        input.getCodeButtonTapped
            .withLatestFrom(contractNum)
            .ignoreNil()
            .withLatestFrom(selectedRestoreMethod.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(RestoreMethodCellModel, String)?> in
                let (inputContractNum, selectedMethod) = args
                
                guard let self = self, !inputContractNum.isEmpty, let uSelectedMethod = selectedMethod else {
                    return .just(nil)
                }
                
                return self.apiWrapper.restore(
                        contractNum: inputContractNum,
                        contactId: uSelectedMethod.method.contactId,
                        code: nil
                    )
                    .map {
                        guard $0 != nil else {
                            return nil
                        }
                        
                        return (uSelectedMethod, inputContractNum)
                    }
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (selectedMethodModel, inputContractNum) = args
                    
                    self.router?.trigger(
                        .pinCode(contractNum: inputContractNum, selectedRestoreMethod: selectedMethodModel.method)
                    )
                    self.routerweb?.trigger(
                        .pinCode(contractNum: inputContractNum, selectedRestoreMethod: selectedMethodModel.method)
                    )
                    self.routerhomepay?.trigger(
                        .pinCode(contractNum: inputContractNum, selectedRestoreMethod: selectedMethodModel.method)
                    )
                }
            )
            .disposed(by: disposeBag)
    
        input.getRestoreMethodsButtonTapped
            .withLatestFrom(contractNum)
            .ignoreNil()
            .flatMapLatest { [weak self] inputContractNum -> Driver<RestoreRequestResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.restore(contractNum: inputContractNum, contactId: nil, code: nil)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { response in
                    let restoreMethods = response
                        .compactMap { RestoreMethod(apiRestoreData: $0) }
                        .map { RestoreMethodCellModel(method: $0, state: .uncheckedActive) }
                    
                    self.selectedRestoreMethod.onNext(nil)
                    self.restoreMethods.onNext(restoreMethods)
                }
            )
            .disposed(by: disposeBag)

        input.itemStateChanged
            .withLatestFrom(self.restoreMethods.asDriver(onErrorJustReturn: [])) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    var (itemIndex, restoreMethods) = args
                    
                    guard let self = self, let index = itemIndex else {
                        return
                    }
                    
                    restoreMethods.enumerated().forEach { offset, _ in
                        if offset == index {
                            restoreMethods[offset].toggleState()
                        } else {
                            restoreMethods[offset].setUncheckedState()
                        }
                    }
                    
                    self.selectedRestoreMethod.onNext(restoreMethods.first { $0.state == .checkedActive })
                    
                    self.restoreMethods.onNext(restoreMethods)
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
            restoreMethods: restoreMethods.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension RestorePasswordViewModel {
    
    struct Input {
        let inputContractNum: Driver<String?>
        let getCodeButtonTapped: Driver<Void>
        let itemStateChanged: Driver<Int?>
        let getRestoreMethodsButtonTapped: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let restoreMethods: Driver<[RestoreMethodCellModel]>
    }
    
}
// swiftlint:enable function_body_length
