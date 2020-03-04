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
            .flatMapLatest { [weak self] contractNumberText -> Driver<Bool?> in
                self?.contractNumber.onNext(contractNumberText)
                
                // TODO: будет какая-то валидация кроме пустоты
                return Observable<Bool?>
                    .just(!(contractNumberText ?? "").isEmpty)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(contractNumValidateTrigger)
            .disposed(by: disposeBag)
        
        input.inputPasswordNumText
            .flatMapLatest { [weak self] passwordText -> Driver<Bool?> in
                self?.password.onNext(passwordText)
                
                // TODO: будет какая-то валидация кроме пустоты
                return Observable<Bool?>
                    .just(!(passwordText ?? "").isEmpty)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
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
            .withLatestFrom(
                contractNumber.asDriver(onErrorJustReturn: nil)
            )
            .withLatestFrom(password.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<Void?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                let (login, password) = args
                
                return
                    self.apiWrapper.addMyPhone(
                        login: login ?? "",
                        password: password ?? "",
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
