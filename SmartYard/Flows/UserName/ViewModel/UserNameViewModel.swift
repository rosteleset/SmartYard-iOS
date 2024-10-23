//
//  UserNameViewModel.swift
//  SmartYard
//
//  Created by admin on 05/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

final class UserNameViewModel: BaseViewModel {
    
    private let accessService: AccessService
    private let apiWrapper: APIWrapper
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    private let router: WeakRouter<AppRoute>
    
    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<AppRoute>
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
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
                    self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        let prepareTransitionTrigger = PublishSubject<Void>()
        
        let isAbleToContinue = input.name
            .map { !($0?.trimmed).isNilOrEmpty }
        
        input.continueTrigger
            .withLatestFrom(input.name)
            .withLatestFrom(input.middleName) { ($0, $1) }
            .flatMap { name, middleName -> Driver<(String, String?)> in
                guard let unwrappedName = name else {
                    return .empty()
                }
                
                return .just((unwrappedName.trimmed, middleName?.trimmed))
            }
            .flatMapLatest { [weak self] args -> Driver<APIClientName?> in
                guard let self = self else {
                    return .just(nil)
                }
                
                let (name, patronymic) = args
                
                return self.apiWrapper.sendName(name: name, patronymic: patronymic)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .map { _ in APIClientName(name: name, patronymic: patronymic) }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .do(
                onNext: { [weak self] name in
                    self?.accessService.clientName = name
                    self?.accessService.appState = .main
                    
                    prepareTransitionTrigger.onNext(())
                }
            )
            .delay(.milliseconds(100))
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isAbleToContinue: isAbleToContinue,
            isLoading: activityTracker.asDriver(),
            prepareTransitionTrigger: prepareTransitionTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension UserNameViewModel {
    
    struct Input {
        let name: Driver<String?>
        let middleName: Driver<String?>
        let continueTrigger: Driver<Void>
    }
    
    struct Output {
        let isAbleToContinue: Driver<Bool>
        let isLoading: Driver<Bool>
        let prepareTransitionTrigger: Driver<Void>
    }
    
}
