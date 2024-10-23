//
//  AuthByContractNumViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

final class AuthByContractNumViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let issueService: IssueService
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService

    init(
        router: WeakRouter<HomeRoute>,
        issueService: IssueService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.router = router
        self.issueService = issueService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
    }
    
    // swiftlint:disable:next function_body_length
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
                    self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
     
        input.forgetPassTapped
            .withLatestFrom(input.inputContractNumText.asDriver(onErrorJustReturn: nil))
            .drive(
                onNext: { [weak self] contractNum in
                    self?.router.trigger(.restorePassword(contractNum: contractNum))
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
                    let okAction = UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { _ in
                        restoreContractDataSubject.onNext(())
                    }
                    
                    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
                    
                    self?.router.trigger(
                        .dialog(
                            title: NSLocalizedString("Create a request for restoration by contract number?", comment: ""),
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
            .withLatestFrom(input.inputContractNumText.asDriver(onErrorJustReturn: nil))
            .withLatestFrom(input.inputPasswordNumText.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
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
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
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
