//
//  ServiceSoonAvailableViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 13.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ServiceSoonAvailableViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let permissionService: PermissionService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private let issueSubject: BehaviorSubject<APIIssueConnect>
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    init(
        router: WeakRouter<HomeRoute>,
        apiWrapper: APIWrapper,
        issueService: IssueService,
        permissionService: PermissionService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        issue: APIIssueConnect
    ) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.permissionService = permissionService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.issueSubject = BehaviorSubject<APIIssueConnect>(value: issue)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: self.activityTracker,
                    errorTracker: self.errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    if (error as NSError) == NSError.PermissionError.noCameraPermission {
                        let msg = NSLocalizedString("To use this feature, go to settings and grant access to the camera", comment: "")
                        
                        self?.router.trigger(.appSettings(
                            title: NSLocalizedString("Can't access camera", comment: ""),
                            message: msg
                        ))
                        
                        return
                    }
                    
                    self?.router.trigger(.alert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
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
                    actionTextTrigger.onNext(issueDeliveryType.changeTypeActionText)
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
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.permissionService.hasAccess(to: .video)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    
                    self.router.trigger(.qrCodeScan(delegate: self))
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
                        .trackActivity(self.activityTracker)
                        .trackError(self.errorTracker)
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
                        .trackActivity(self.activityTracker)
                        .trackError(self.errorTracker)
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
                        .trackActivity(self.activityTracker)
                        .trackError(self.errorTracker)
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

extension ServiceSoonAvailableViewModel: QRCodeScanViewModelDelegate {
    
    func qrCodeScanViewModel(_ viewModel: QRCodeScanViewModel, didExtractCode code: String) {
        router.rx
            .trigger(.back)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .registerQR(qr: code)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .drive(
                onNext: { [weak self] _ in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
