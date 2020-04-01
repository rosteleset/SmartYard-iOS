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
    private let issueService: IssueService
    
    private let requestType: ServiceRequestType
    private let address: String
    
    init(router: WeakRouter<HomeRoute>, issueService: IssueService, requestType: ServiceRequestType, address: String) {
        self.router = router
        self.issueService = issueService
        self.requestType = requestType
        self.address = address
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
                        of: "{value}", with: (self.address)
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
        
        comeInOfficeTrigger
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.issueService
                        .sendApproveAddressInOfficeIssue(address: self.address)
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
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.issueService
                        .sendApproveAddressInOfficeIssue(address: self.address)
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
            changeVisibilityQrCodeElementsTrigger: changeVisibilityQrCodeElementsTrigger.asDriverOnErrorJustComplete()
        )
    }
    
}

extension ServiceSoonAvailableViewModel {
    
    struct Input {
        let qrCodeTapped: Driver<Void>
        let actionTapped: Driver<Void>
        let viewWillAppearTrigger: Driver<Bool>
    }
    
    struct Output {
        let titleImageTrigger: Driver<UIImage?>
        let hintTextTrigger: Driver<String?>
        let actionTextTrigger: Driver<String?>
        let changeVisibilityQrCodeElementsTrigger: Driver<Bool>
    }
    
}
