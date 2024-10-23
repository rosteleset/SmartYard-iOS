//
//  ServiceUnavailableViewModel.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

final class ServiceUnavailableViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private let service: SettingsServiceType
    private let address: String
    private let contractName: String?
    
    private let issueService: IssueService
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(router: WeakRouter<SettingsRoute>,
         service: SettingsServiceType,
         address: String,
         issueService: IssueService,
         contractName: String?
    ) {
        self.router = router
        self.service = service
        self.address = address
        self.issueService = issueService
        self.contractName = contractName
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
            .drive(
                onNext: { [weak self] _ in
                    var userInfo = [AnyHashable: Any]()
                    
                    userInfo[NotificationKeys.serviceActionKey] = SettingsServiceAction.talkAboutActivation.rawValue
                    
                    if let contractName = self?.contractName {
                        userInfo[NotificationKeys.contractNameKey] = contractName
                    }
                    
                    if let service = self?.service.rawValue {
                        userInfo[NotificationKeys.serviceTypeKey] = service
                    }
                    
                    NotificationCenter.default.post(name: .chatRequested, object: nil, userInfo: userInfo)
                    
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            service: .just(service),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension ServiceUnavailableViewModel {
    
    struct Input {
        let dismissTrigger: Driver<Void>
        let sendRequestTrigger: Driver<Void>
    }
    
    struct Output {
        let service: Driver<SettingsServiceType>
        let isLoading: Driver<Bool>
    }
    
}
