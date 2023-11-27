//
//  AvailableSericesViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator

class AvailableServicesViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    private let serviceItemsSubject: BehaviorSubject<[ServiceModel]>
    private let addressSubject: BehaviorSubject<String?>
    
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
        
        var serviceModels = services.enumerated().map { offset, element in
            ServiceModel(
                id: String(offset),
                icon: element.icon,
                name: element.title,
                description: element.description,
                state: element.isAvailableByDefault ? .checkedInactive : .uncheckedActive
            )
        }
        
        serviceModels = serviceModels.sorted { $0.state.sortOrder < $1.state.sortOrder }

        addressSubject = BehaviorSubject<String?>(value: address)
        serviceItemsSubject = BehaviorSubject<[ServiceModel]>(value: serviceModels)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let сonnectSelectedServicesTrigger = PublishSubject<(String, [ServiceModel])>()
        let сonnectOnlyNonHousesServicesTrigger = PublishSubject<(String, [ServiceModel])>()
        
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.nextTapped
            .withLatestFrom(serviceItemsSubject.asDriver(onErrorJustReturn: []))
            .withLatestFrom(addressSubject.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .drive(
                onNext: { [weak self] services, address in
                    guard let self = self, let address = address else {
                        return
                    }
                     /*
                     1) Если есть общедомовые сервисы и другие сервисы НЕ выбраны
                     - переходим на экран выбора способа подтверждения курьер / офис.
                     2) Если есть общедомовые услуги и выбран какой-либо другой сервис
                     - делаем заявку sendComeInOfficeMyselfIssue
                     3) Если НЕТ общедомовых услуг и выбран какой-либо сервис -
                     делаем заявку "заявка только на услугу"
                     */
                    
                    let selectedServices = services.filter { $0.state == .checkedActive }
                    let housesServices = services.filter { $0.state == .checkedInactive }
                    
                    switch (housesServices.isEmpty, selectedServices.isEmpty) {
                    case (false, true): self.router.trigger(.confirmAddress(address: address)) // 1
                    case (false, false): сonnectSelectedServicesTrigger.onNext((address, selectedServices)) // 2
                    case (true, false): сonnectOnlyNonHousesServicesTrigger.onNext((address, selectedServices)) // 3
                    default: self.router.trigger(.alert(
                        title: NSLocalizedString("No service selected", comment: ""),
                        message: nil
                    ))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        сonnectSelectedServicesTrigger
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] args -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                let (addressString, services) = args
                
                return self.issueService
                    .sendComeInOfficeMyselfIssue(
                        address: addressString,
                        serviceNames: services.map { $0.name }
                    )
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
        
        сonnectOnlyNonHousesServicesTrigger
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] args -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                let (addressString, services) = args
                
                return self.issueService
                    .sendConnectOnlyNonHousesServicesIssue(
                        address: addressString,
                        serviceNames: services.map { $0.name }
                    )
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
