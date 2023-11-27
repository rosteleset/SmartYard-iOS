//
//  ServicesActivationRequestViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxCocoa
import RxSwift

class ServicesActivationRequestViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    private let address: String

    private let serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: [])

    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper, issueService: IssueService, address: String) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.address = address
    }
    
    // swiftlint:disable:next function_body_length
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
                    
                    data[index].toggleState()
                    
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
        let domophone = NSLocalizedString("Smart intercom", comment: "")
        let cctv = NSLocalizedString("Video surveillance", comment: "")
        let internet = NSLocalizedString("Internet", comment: "")
        let iptv = NSLocalizedString("Cable TV", comment: "")
        let phone = NSLocalizedString("Wired Phone", comment: "")
        
        return [
            ServiceModel(id: "0", icon: "domophone", name: domophone, description: "", state: .uncheckedActive),
            ServiceModel(id: "1", icon: "cctv", name: cctv, description: "", state: .uncheckedActive),
            ServiceModel(id: "2", icon: "internet", name: internet, description: "", state: .uncheckedActive),
            ServiceModel(id: "3", icon: "iptv", name: iptv, description: "", state: .uncheckedActive),
            ServiceModel(id: "4", icon: "phone", name: phone, description: "", state: .uncheckedActive)
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
