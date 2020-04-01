//
//  ServiceSoonAvailableViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ServiceSoonAvailableViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    private let requestType: ServiceRequestType
    private let issue: APIIssueConnect
    
    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper, issueService: IssueService, issue: APIIssueConnect) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.requestType = issue.isDeliveredByCourier ? .courierRequest : .officeRequest
        self.issue = issue
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let titleImageTrigger = PublishSubject<UIImage?>()
        let hintTextTrigger = PublishSubject<String?>()
        let actionTextTrigger = PublishSubject<String?>()
        let changeVisibilityQrCodeElementsTrigger = PublishSubject<Bool>()
        
        let callCourierTrigger = PublishSubject<Void>()
        let comeInOfficeTrigger = PublishSubject<Void>()
        
        input.viewWillAppearTrigger
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    titleImageTrigger.onNext(self.requestType.image)
                    actionTextTrigger.onNext(self.requestType.actionText)
                    changeVisibilityQrCodeElementsTrigger.onNext(self.requestType == .officeRequest)
                    
                    guard self.requestType == .courierRequest else {
                        hintTextTrigger.onNext(self.requestType.hintText)
                        return
                    }
                    
                    let hintText = self.requestType.hintText.replacingOccurrences(
                        of: "{value}", with: (self.issue.address ?? "")
                    )
                    
                    hintTextTrigger.onNext(hintText)
                }
            )
            .disposed(by: disposeBag)
                
        input.qrCodeTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.actionTapped
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    switch self.requestType {
                    case .officeRequest: comeInOfficeTrigger.onNext(())
                    case .courierRequest: callCourierTrigger.onNext(())
                    }
                }
            )
            .disposed(by: disposeBag)
        
        input.cancelTapped
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.apiWrapper.cancelIssue(key: self.issue.key)
                        .trackActivity(activityTracker)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
        
        comeInOfficeTrigger
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self, let address = self.issue.address else {
                    return .empty()
                }
                
                return
                    self.issueService
                        .sendApproveAddressInOfficeIssue(address: address)
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
        
        callCourierTrigger
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self, let address = self.issue.address else {
                    return .empty()
                }
                
                return
                    self.issueService
                        .sendApproveAddressInOfficeIssue(address: address)
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
        
        return Output(
            titleImageTrigger: titleImageTrigger.asDriverOnErrorJustComplete(),
            hintTextTrigger: hintTextTrigger.asDriverOnErrorJustComplete(),
            actionTextTrigger: actionTextTrigger.asDriverOnErrorJustComplete(),
            changeVisibilityQrCodeElementsTrigger: changeVisibilityQrCodeElementsTrigger.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver(onErrorJustReturn: false)
        )
    }
    
}

extension ServiceSoonAvailableViewModel {
    
    struct Input {
        let qrCodeTapped: Driver<Void>
        let actionTapped: Driver<Void>
        let viewWillAppearTrigger: Driver<Bool>
        let cancelTapped: Driver<Void>
    }
    
    struct Output {
        let titleImageTrigger: Driver<UIImage?>
        let hintTextTrigger: Driver<String?>
        let actionTextTrigger: Driver<String?>
        let changeVisibilityQrCodeElementsTrigger: Driver<Bool>
        let isLoading: Driver<Bool>
    }
    
}
