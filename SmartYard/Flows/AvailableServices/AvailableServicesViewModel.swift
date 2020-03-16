//
//  AvailableSericesViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class AvailableServicesViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    private let serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: [])
    private let addressSubject = BehaviorSubject<String?>(value: nil)
    
    private let address: String
    private let services: [ServiceModel]
    
    init(
        router: WeakRouter<HomeRoute>,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        address: String,
        services: [APIServiceModel]
    ) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.address = address
        
        var serviceModels = [ServiceModel]()
        
        services.enumerated().forEach { offset, element in
            serviceModels.append(
                ServiceModel(
                    id: String(offset),
                    icon: element.icon,
                    name: element.title,
                    description: element.description,
                    state: element.isAvailableByDefault ? .checkedInactive : .uncheckedActive
                )
            )
        }

        self.services = serviceModels.sorted(by: { $0.state < $1.state })
    }
    
    func transform(input: Input) -> Output {
        let sendConnectServicesIssueTrigger = PublishSubject<(String, [ServiceModel])>()
        
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        addressSubject.onNext(address)
        serviceItemsSubject.onNext(services)
        
        input.nextTapped
            .drive(
                onNext: { [weak self] in
                    guard let self = self,
                          let data = try? self.serviceItemsSubject.value()
                    else {
                        return
                    }
                    
                    let selectedServices = data.filter { $0.state == .checkedActive }
                    
                    guard !selectedServices.isEmpty else {
                        self.router.trigger(.confirmAddress)
                        return
                    }
                    
                    sendConnectServicesIssueTrigger.onNext((self.address, selectedServices))
                }
            )
            .disposed(by: disposeBag)
        
        sendConnectServicesIssueTrigger
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] args -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                let (addressString, services) = args
                let selectedServices = services.compactMap { SettingsServiceType(rawValue: $0.icon) }
                
                return self.issueService
                    .sendConnectSelectedServicesIssue(
                        address: addressString,
                        services: selectedServices
                    )
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
        
        input.serviceStateChanged
            .drive(
                onNext: { [weak self] index in
                    guard let self = self,
                          let index = index,
                          var data = try? self.serviceItemsSubject.value()
                    else {
                        return
                    }
                    
                    data[index].toogleState()
                    
                    self.serviceItemsSubject.onNext(data)
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
            serviceItems: serviceItemsSubject.asDriver(onErrorJustReturn: []),
            addressSubject: addressSubject.asDriver(onErrorJustReturn: nil),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension AvailableServicesViewModel {
    
    struct Input {
        let nextTapped: Driver<Void>
        let serviceStateChanged: Driver<Int?>
        let viewWillAppearTrigger: Driver<Bool>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let serviceItems: Driver<[ServiceModel]>
        let addressSubject: Driver<String?>
        let isLoading: Driver<Bool>
    }
    
}
