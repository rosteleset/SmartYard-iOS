//
//  AddressConfirmationViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class AddressConfirmationViewModel: BaseViewModel {
    
//    private let router: WeakRouter<HomeRoute>?
    private let router: WeakRouter<MyYardRoute>?
    private let routerhomepay: WeakRouter<HomePayRoute>?
    private let routerweb: WeakRouter<HomeWebRoute>?
//    private let routerintercom: WeakRouter<IntercomWebRoute>?
    
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    private let address: String
    
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
    
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let offices = BehaviorSubject<[APIOffice]>(value: [])
        
        apiWrapper.getOffices()
            .trackActivity(activityTracker)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { response in
                    offices.onNext(response)
                }
            )
            .disposed(by: disposeBag)
        
        input.confirmByCourierTapped
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.issueService.sendApproveAddressByCourierIssue(address: self.address)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
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
        
        input.confirmInOfficeTrigger
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.issueService.sendApproveAddressInOfficeIssue(address: self.address)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .mapToVoid()
            .drive(
                onNext: { [weak self] in
                    self?.router?.trigger(.main)
                    self?.routerweb?.trigger(.main)
                    self?.routerhomepay?.trigger(.main)
                    NotificationCenter.default.post(name: .addressAdded, object: nil)
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
        
        return Output(isLoading: activityTracker.asDriver(), offices: offices.asDriver(onErrorJustReturn: []))
    }
    
}

extension AddressConfirmationViewModel {
    
    struct Input {
        let confirmByCourierTapped: Driver<Void>
        let confirmInOfficeTrigger: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let offices: Driver<[APIOffice]>
    }
    
}
// swiftlint:enable function_body_length
