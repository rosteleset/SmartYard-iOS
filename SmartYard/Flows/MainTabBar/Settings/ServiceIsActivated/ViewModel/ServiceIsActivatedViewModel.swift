//
//  ServiceIsActivatedViewModel.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class ServiceIsActivatedViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    private let issueService: IssueService
    private let clientId: String
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(
        router: WeakRouter<SettingsRoute>,
        issueService: IssueService,
        clientId: String
    ) {
        self.router = router
        self.issueService = issueService
        self.clientId = clientId
    }
    
    func transform(_ input: Input) -> Output {
        input.dismissTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.changePlanTrigger
            .asDriver()
            .debounce(.milliseconds(25))
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.issueService.sendChangeTariffIssue(clientId: self.clientId)
                    .trackError(self.errorTracker)
                    .trackActivity(self.activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .drive(
                onNext: { [weak self] result in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(isLoading: activityTracker.asDriver())
    }
    
}

extension ServiceIsActivatedViewModel {
    
    struct Input {
        let dismissTrigger: Driver<Void>
        let changePlanTrigger: Driver<Void>
    }

    struct Output {
        let isLoading: Driver<Bool>
    }
    
}
