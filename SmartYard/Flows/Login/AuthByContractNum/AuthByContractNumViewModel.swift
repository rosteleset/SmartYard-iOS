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
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    let contractNumber = BehaviorSubject<String?>(value: nil)
    let password = BehaviorSubject<String?>(value: nil)
    
    init(router: WeakRouter<HomeRoute>, issueService: IssueService) {
        self.router = router
        self.issueService = issueService
    }
    
    func transform(input: Input) -> Output {
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
            .flatMapLatest { [weak self] contractNumberText -> Driver<Bool?> in
                self?.contractNumber.onNext(contractNumberText)
                
                return Observable<Bool?>
                    .just(!contractNumberText.isEmpty)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { isCorrect in
                    contractNumValidateTrigger.onNext(isCorrect)
                }
            )
            .disposed(by: disposeBag)
        
        input.inputPasswordNumText
            .flatMapLatest { [weak self] passwordText -> Driver<Bool?> in
                self?.password.onNext(passwordText)
                
                return Observable<Bool?>
                    .just(!passwordText.isEmpty)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { isCorrect in
                    passwordValidateTrigger.onNext(isCorrect)
                }
            )
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
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .merge(
                contractNumValidateTrigger.asDriverOnErrorJustComplete(),
                passwordValidateTrigger.asDriverOnErrorJustComplete()
            )
            .drive(inputValidateTrigger)
            .disposed(by: disposeBag)
        
        input.signInTapped
            .withLatestFrom(
                inputValidateTrigger.asDriverOnErrorJustComplete()
            )
            .filter { $0 != false }
            .drive(
                onNext: { [weak self] _ in
                   // self?.router.trigger()
                }
            )
            .disposed(by: disposeBag)
        
        input.signInTapped
            .drive(
                onNext: {
                    self.router.trigger(.inputAddress)
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
        
        let inputContractNumText: Driver<String>
        let inputPasswordNumText: Driver<String>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let contractNumValidateTrigger: Driver<Bool>
        let passwordValidateTrigger: Driver<Bool>
    }
    
}
