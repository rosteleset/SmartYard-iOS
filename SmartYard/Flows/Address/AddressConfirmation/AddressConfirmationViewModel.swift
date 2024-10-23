//
//  AddressConfirmationViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

final class AddressConfirmationViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    private let address: String
    
    init(
        router: WeakRouter<HomeRoute>,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        address: String
    ) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.address = address
    }
    
    // swiftlint:disable:next function_body_length
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
                    self?.router.trigger(.main)
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
                    self?.router.trigger(.main)
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
