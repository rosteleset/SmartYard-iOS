//
//  ServiceIsNotActivatedViewModel.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class ServiceIsNotActivatedViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private let service: SettingsServiceType
    private let clientId: String?
    private let address: String
    
    private let issueService: IssueService
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(
        router: WeakRouter<SettingsRoute>,
        service: SettingsServiceType,
        clientId: String?,
        address: String,
        issueService: IssueService
    ) {
        self.router = router
        self.service = service
        self.clientId = clientId
        self.address = address
        self.issueService = issueService
    }
    
    func transform(_ input: Input) -> Output {
        input.dismissTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.sendRequestTrigger
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

extension ServiceIsNotActivatedViewModel {
    
    struct Input {
        let dismissTrigger: Driver<Void>
        let sendRequestTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
    }
    
}
