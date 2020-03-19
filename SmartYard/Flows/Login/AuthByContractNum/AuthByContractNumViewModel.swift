//
//  AuthByContractNumViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class AuthByContractNumViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let issueService: IssueService
    private let apiWrapper: APIWrapper
    
    let contractNumber = BehaviorSubject<String?>(value: nil)
    let password = BehaviorSubject<String?>(value: nil)
    
    init(
        router: WeakRouter<HomeRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper
    ) {
        self.router = router
        self.issueService = issueService
        self.apiWrapper = apiWrapper
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.forgetPassTapped
            .withLatestFrom(contractNumber.asDriver(onErrorJustReturn: nil))
            .flatMapLatest { [weak self] contract -> Driver<RestoreRequestResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.restore(contractNum: contract)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .withLatestFrom(contractNumber.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (response, contractNum) = args
                    let resetMethodsArr = response?.compactMap { response in
                        ResetMethodType(rawValue: response.contact)
                    } ?? []
                
                    self?.router.trigger(.restorePassword(contractNum: contractNum, resetMethods: resetMethodsArr))
                }
            )
            .disposed(by: disposeBag)
        
        input.forgetEverythingTapped
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
        
        input.noContractTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.inputAddress)
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
            .withLatestFrom(contractNumber.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(password.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<Void?> in
                let (login, password) = args
                
                guard let self = self, let uLogin = login, let uPassword = password else {
                    return .just(nil)
                }
                
                return self.apiWrapper
                    .addMyPhone(
                        login: uLogin.trimmed,
                        password: uPassword.trimmed,
                        comment: nil,
                        useForNotifications: true
                    )
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.main)
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
        
        let inputContractNumText: Driver<String?>
        let inputPasswordNumText: Driver<String?>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let isAbleToProceed: Driver<Bool>
    }
    
}
