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

    private let issueSubject: BehaviorSubject<APIIssueConnect>
    
    init(router: WeakRouter<HomeRoute>, apiWrapper: APIWrapper, issueService: IssueService, issue: APIIssueConnect) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.issueSubject = BehaviorSubject<APIIssueConnect>(value: issue)
    }
    
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let titleImageTrigger = PublishSubject<UIImage?>()
        let hintTextTrigger = PublishSubject<String?>()
        let actionTextTrigger = PublishSubject<String?>()
        let changeVisibilityQrCodeElementsTrigger = PublishSubject<Bool>()
        
        input.viewWillAppearTrigger
            .withLatestFrom(issueSubject.asDriverOnErrorJustComplete())
            .drive(
                onNext: { issue in
                    let issueDeliveryType: IssueDeliveryType = issue.isDeliveredByCourier ? .courier : .office
                    titleImageTrigger.onNext(issueDeliveryType.image)
                    actionTextTrigger.onNext(issueDeliveryType.actionText)
                    changeVisibilityQrCodeElementsTrigger.onNext(issueDeliveryType == .office)
                    
                    guard issueDeliveryType == .courier else {
                        hintTextTrigger.onNext(issueDeliveryType.hintText)
                        return
                    }
                    
                    let hintText = issueDeliveryType.hintText.replacingOccurrences(
                        of: "{value}", with: (issue.address ?? "")
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
            .withLatestFrom(issueSubject.asDriverOnErrorJustComplete())
            .flatMapLatest { [weak self] issue -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                let newIssueDeliveryType: IssueDeliveryType = issue.isDeliveredByCourier ? .office : .courier
                
                return
                    self.apiWrapper.changeDeliveryMethod(newMethod: newIssueDeliveryType, key: issue.key)
                        .trackActivity(activityTracker)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .withLatestFrom(issueSubject.asDriverOnErrorJustComplete())
            .flatMapLatest { [weak self] issue -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                let newDeliveryType: IssueDeliveryType = issue.isDeliveredByCourier ? .office : .courier
                
                return
                    self.apiWrapper.sendCommentAfterDeliveryMethodChanging(newMethod: newDeliveryType, key: issue.key)
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
        
        input.cancelTapped
            .withLatestFrom(issueSubject.asDriverOnErrorJustComplete())
            .flatMapLatest { [weak self] issue -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.apiWrapper.cancelIssue(key: issue.key)
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
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
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
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let titleImageTrigger: Driver<UIImage?>
        let hintTextTrigger: Driver<String?>
        let actionTextTrigger: Driver<String?>
        let changeVisibilityQrCodeElementsTrigger: Driver<Bool>
        let isLoading: Driver<Bool>
    }
    
}
