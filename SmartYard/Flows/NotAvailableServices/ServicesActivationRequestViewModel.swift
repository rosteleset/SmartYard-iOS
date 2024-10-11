//
//  ServicesActivationRequestViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import XCoordinator
import RxCocoa
import RxSwift

class ServicesActivationRequestViewModel: BaseViewModel {
    
//    private let router: WeakRouter<HomeRoute>?
    private let router: WeakRouter<MyYardRoute>?
    private let routerhomepay: WeakRouter<HomePayRoute>?
    private let routerweb: WeakRouter<HomeWebRoute>?
//    private let routerintercom: WeakRouter<IntercomWebRoute>?

    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    private let address: String

    private let serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: [])

    init(
        routerweb: WeakRouter<HomeWebRoute>,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        address: String
    ) {
        self.router = nil
        self.routerweb = routerweb
        self.routerhomepay = nil
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.address = address
    }
    
    init(
        routerhomepay: WeakRouter<HomePayRoute>,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        address: String
    ) {
        self.router = nil
        self.routerweb = nil
        self.routerhomepay = routerhomepay
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.address = address
    }
    
    init(
        router: WeakRouter<MyYardRoute>,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        address: String
    ) {
        self.router = router
        self.routerweb = nil
        self.routerhomepay = nil
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.address = address
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.viewWillAppearTrigger
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    self.serviceItemsSubject.onNext(self.getServiceModels())
                }
            )
            .disposed(by: disposeBag)
        
        input.sendRequestTapped
            .withLatestFrom(serviceItemsSubject.asDriver(onErrorJustReturn: []))
            .filter { !$0.isEmpty }
            .flatMapLatest { [weak self] servicesData -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                let serviceNames = servicesData
                    .filter { $0.state == .checkedActive }
                    .map { $0.name }
                
                return self.issueService
                    .sendUnavailableAddressConnectionIssue(address: self.address, serviceNames: serviceNames)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    self?.router?.trigger(.main)
                    self?.routerweb?.trigger(.main)
                    self?.routerhomepay?.trigger(.main)
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
                    
                    data[index].toggleState()
                    
                    self.serviceItemsSubject.onNext(data)
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router?.trigger(.back)
                    self?.routerweb?.trigger(.back)
                    self?.routerhomepay?.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        let isSomeServiceSelected = serviceItemsSubject
            .asDriver(onErrorJustReturn: [])
            .map { services -> Bool in
                services.contains { $0.state == .checkedActive }
            }

        return Output(
            serviceItems: serviceItemsSubject.asDriver(onErrorJustReturn: []),
            isSelectedSomeService: isSomeServiceSelected.asDriver(onErrorJustReturn: false),
            isLoading: activityTracker.asDriver()
        )
    }
    
    private func getServiceModels() -> [ServiceModel] {
        return [
            ServiceModel(id: "0", icon: "domophone", name: "Умный домофон", description: "", state: .uncheckedActive),
            ServiceModel(id: "1", icon: "cctv", name: "Видеонаблюдение", description: "", state: .uncheckedActive),
            ServiceModel(id: "2", icon: "internet", name: "Интернет", description: "", state: .uncheckedActive),
            ServiceModel(id: "3", icon: "iptv", name: "Телевидение", description: "", state: .uncheckedActive),
            ServiceModel(id: "4", icon: "phone", name: "Телефония", description: "", state: .uncheckedActive)
        ]
    }
    
}

extension ServicesActivationRequestViewModel {
    
    struct Input {
        let sendRequestTapped: Driver<Void>
        let serviceStateChanged: Driver<Int?>
        let viewWillAppearTrigger: Driver<Bool>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let serviceItems: Driver<[ServiceModel]>
        let isSelectedSomeService: Driver<Bool>
        let isLoading: Driver<Bool>
    }
    
}
// swiftlint:enable function_body_length
