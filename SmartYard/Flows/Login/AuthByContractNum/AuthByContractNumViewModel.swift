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
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
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
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let contractNumValidateTrigger = BehaviorSubject<Bool>(value: false)
        let passwordValidateTrigger = BehaviorSubject<Bool>(value: false)
        let inputValidateTrigger = BehaviorSubject<Bool>(value: false)
        
        input.forgetPassTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.inputContractNumText
            .map { !$0.isNilOrEmpty }
            .drive(contractNumValidateTrigger)
            .disposed(by: disposeBag)
        
        input.inputPasswordNumText
            .map { !$0.isNilOrEmpty }
            .drive(passwordValidateTrigger)
            .disposed(by: disposeBag)
        
        input.forgetEverythingTapped
            .debounce(.milliseconds(25))
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.issueService.sendNothingRememberIssue()
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
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
        
        Driver
            .combineLatest(
                contractNumValidateTrigger.asDriverOnErrorJustComplete(),
                passwordValidateTrigger.asDriverOnErrorJustComplete()
            )
            .map { args in
                let (isContractNumberValid, isPasswordValid) = args
                return isContractNumberValid && isPasswordValid
            }
            .drive(inputValidateTrigger)
            .disposed(by: disposeBag)
        
        input.signInTapped
            .withLatestFrom(inputValidateTrigger.asDriverOnErrorJustComplete())
            .isTrue()
            .withLatestFrom(contractNumber.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(password.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<Void?> in
                let (login, password) = args
                
                guard let self = self, let unwrappedLogjn = login, let unwrappedPassword = password else {
                    return .just(nil)
                }
                
                return self.apiWrapper
                    .addMyPhone(
                        login: unwrappedLogjn,
                        password: unwrappedPassword,
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
            contractNumValidateTrigger: contractNumValidateTrigger.asDriverOnErrorJustComplete(),
            passwordValidateTrigger: passwordValidateTrigger.asDriverOnErrorJustComplete()
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
        let contractNumValidateTrigger: Driver<Bool>
        let passwordValidateTrigger: Driver<Bool>
    }
    
}
