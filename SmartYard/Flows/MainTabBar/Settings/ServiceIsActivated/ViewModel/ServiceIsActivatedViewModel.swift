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
    private let clientId: String?
    private let address: String
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(
        router: WeakRouter<SettingsRoute>,
        issueService: IssueService,
        clientId: String?,
        address: String
    ) {
        self.router = router
        self.issueService = issueService
        self.clientId = clientId
        self.address = address
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
            .drive(
                onNext: { [weak self] _ in
                    var userInfo = [AnyHashable: Any]()
                    
                    if let clientId = self?.clientId {
                        userInfo[NotificationKeys.clientIdKey] = clientId
                    }
                    
                    NotificationCenter.default.post(name: .chatRequested, object: nil, userInfo: userInfo)
                    
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
