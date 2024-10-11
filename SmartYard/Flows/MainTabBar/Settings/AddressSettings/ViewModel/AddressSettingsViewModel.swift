//
//  AddressSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable type_body_length function_body_length cyclomatic_complexity file_length

import RxCocoa
import RxSwift
import XCoordinator

class AddressSettingsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private let flatId: String
    private let clientId: String?
    private let address: String
    private let isContractOwner: Bool
    private let hasDomophone: Bool
    private let router: WeakRouter<SettingsRoute>
    
    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    init(
        apiWrapper: APIWrapper,
        issueService: IssueService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        flatId: String,
        clientId: String?,
        address: String,
        isContractOwner: Bool,
        hasDomophone: Bool,
        router: WeakRouter<SettingsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.issueService = issueService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.flatId = flatId
        self.clientId = clientId
        self.address = address
        self.isContractOwner = isContractOwner
        self.hasDomophone = hasDomophone
        self.router = router
    }
    
    func transform(_ input: Input) -> Output {
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
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        let isCmsEnabledSubject = BehaviorSubject<Bool>(value: false)
        let areCallsEnabledSubject = BehaviorSubject<Bool>(value: false)
        let isWhiteRabbitEnabledSubject = BehaviorSubject<Bool>(value: false)
        let arePaperBillsEnabledSubject = BehaviorSubject<Bool?>(value: nil)
        let areLogsEnabledSubject = BehaviorSubject<Bool?>(value: nil)
        let areLogsVisibleOnlyForOwnerSubject = BehaviorSubject<Bool?>(value: nil)
        let isFRSEnabledSubject = BehaviorSubject<Bool?>(value: nil)
        
        let interactionBlockingRequestTracker = ActivityTracker()
        
        if hasDomophone {
            apiWrapper
                .getCurrentIntercomState(flatId: flatId)
                .trackError(errorTracker)
                .trackActivity(interactionBlockingRequestTracker)
                .asDriver(onErrorJustReturn: nil)
                .ignoreNil()
                .drive(
                    onNext: { state in
                        isCmsEnabledSubject.onNext(state.cms)
                        areCallsEnabledSubject.onNext(state.voip)
                        isWhiteRabbitEnabledSubject.onNext(state.whiteRabbit)
                        arePaperBillsEnabledSubject.onNext(state.paperBill)
                        
                        switch state.disablePlog {
                        case true: areLogsEnabledSubject.onNext(false)
                        case false: areLogsEnabledSubject.onNext(true)
                        default: areLogsEnabledSubject.onNext(nil)
                        }
                        
                        areLogsVisibleOnlyForOwnerSubject.onNext(state.hiddenPlog)
                        
                        switch state.frsDisabled {
                        case true: isFRSEnabledSubject.onNext(false)
                        case false: isFRSEnabledSubject.onNext(true)
                        default: isFRSEnabledSubject.onNext(nil)
                        }
                    }
                )
                .disposed(by: disposeBag)
        }
        
        input.cmsTrigger
            .withLatestFrom(isCmsEnabledSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self, self.hasDomophone else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .setIntercomCMSState(flatId: self.flatId, isEnabled: !isEnabled)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { state in
                    isCmsEnabledSubject.onNext(state.cms)
                }
            )
            .disposed(by: disposeBag)
        
        input.voipTrigger
            .withLatestFrom(areCallsEnabledSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self, self.hasDomophone else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .setIntercomVoIPState(flatId: self.flatId, isEnabled: !isEnabled)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { state in
                    areCallsEnabledSubject.onNext(state.voip)
                }
            )
            .disposed(by: disposeBag)
        
        input.whiteRabbitTrigger
            .withLatestFrom(isWhiteRabbitEnabledSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self, self.hasDomophone else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .setIntercomWhiteRabbitState(flatId: self.flatId, isEnabled: !isEnabled)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { state in
                    isWhiteRabbitEnabledSubject.onNext(state.whiteRabbit)
                }
            )
            .disposed(by: disposeBag)
        
        input.paperBillTrigger
            .withLatestFrom(arePaperBillsEnabledSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self, self.hasDomophone else {
                    return .empty()
                }
                
                let isEnabled = isEnabled ?? true
                
                return self.apiWrapper
                    .setIntercomPaperBillState(flatId: self.flatId, isEnabled: !isEnabled)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { state in
                    arePaperBillsEnabledSubject.onNext(state.paperBill)
                }
            )
            .disposed(by: disposeBag)
        
        input.logsTrigger
            .withLatestFrom(areLogsEnabledSubject.asDriver(onErrorJustReturn: nil))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self, self.hasDomophone else {
                    return .empty()
                }
                
                let isEnabled = isEnabled ?? true
                
                return self.apiWrapper
                    .setIntercomDisablePlogState(flatId: self.flatId, isDisabled: isEnabled)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] state in
                    switch state.disablePlog {
                    case true: areLogsEnabledSubject.onNext(false)
                    case false: areLogsEnabledSubject.onNext(true)
                    default: areLogsEnabledSubject.onNext(nil)
                    }
                    
                    self?.apiWrapper.forceUpdateAddress = true
                    self?.apiWrapper.forceUpdateSettings = true
                    
                    NotificationCenter.default.post(name: .addressNeedUpdate, object: nil)
                    
                }
            )
            .disposed(by: disposeBag)
        
        input.hiddenTrigger
            .withLatestFrom(areLogsVisibleOnlyForOwnerSubject.asDriver(onErrorJustReturn: nil))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self, self.hasDomophone else {
                    return .empty()
                }
                
                let isEnabled = isEnabled ?? true
                
                return self.apiWrapper
                    .setIntercomHiddenPlogState(flatId: self.flatId, isHidden: !isEnabled)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { state in
                    areLogsVisibleOnlyForOwnerSubject.onNext(state.hiddenPlog)
                }
            )
            .disposed(by: disposeBag)
        
        input.frsTrigger
            .withLatestFrom(isFRSEnabledSubject.asDriver(onErrorJustReturn: nil))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self, self.hasDomophone else {
                    return .empty()
                }
                
                let isEnabled = isEnabled ?? true
                
                return self.apiWrapper
                    .setIntercomFRSDisabledState(flatId: self.flatId, isDisabled: isEnabled)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { state in
                    switch state.frsDisabled {
                    case true: isFRSEnabledSubject.onNext(false)
                    case false: isFRSEnabledSubject.onNext(true)
                    default: isFRSEnabledSubject.onNext(nil)
                    }
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
        
        input.deleteTrigger
            .drive(
                onNext: { [weak self] in
                    self?.deleteAddress()
                }
            )
            .disposed(by: disposeBag)
        
        input.whiteRabbitHintTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.showModal(withContent: .aboutWhiteRabbit))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            address: .just(address),
            isCmsEnabled: isCmsEnabledSubject.asDriver(onErrorJustReturn: false),
            areCallsEnabled: areCallsEnabledSubject.asDriver(onErrorJustReturn: false),
            isWhiteRabbitEnabled: isWhiteRabbitEnabledSubject.asDriver(onErrorJustReturn: false),
            arePaperBillsEnabled: arePaperBillsEnabledSubject.asDriver(onErrorJustReturn: nil),
            areLogsEnabled: areLogsEnabledSubject.asDriver(onErrorJustReturn: nil),
            areLogsVisibleOnlyForOwner: areLogsVisibleOnlyForOwnerSubject.asDriver(onErrorJustReturn: nil),
            isFRSEnabled: isFRSEnabledSubject.asDriver(onErrorJustReturn: nil),
            ringtone: .just("Нота"),
            hasDomophone: .just(hasDomophone),
            isLoading: activityTracker.asDriver(),
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver()
        )
    }
    
    private func deleteAddress() {
        guard !isContractOwner else {
            router.trigger(.addressDeletion(delegate: self))
            return
        }
        
        let noAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)
        
        let yesAction = UIAlertAction(title: "Да", style: .destructive) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            self.apiWrapper
                .deleteAddress(flatId: self.flatId, clientId: self.clientId)
                .trackActivity(self.activityTracker)
                .trackError(self.errorTracker)
                .asDriver(onErrorJustReturn: nil)
                .ignoreNil()
                .drive(
                    onNext: { [weak self] in
                        self?.apiWrapper.forceUpdateAddress = true
                        self?.apiWrapper.forceUpdateSettings = true
                        self?.apiWrapper.forceUpdatePayments = true
                        
                        NotificationCenter.default.post(.init(name: .addressDeleted, object: nil))
                        
                        self?.router.trigger(.back)
                    }
                )
                .disposed(by: self.disposeBag)
        }
        
        router.trigger(.dialog(title: "Вы уверены?", message: nil, actions: [noAction, yesAction]))
    }
    
}

extension AddressSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let deleteTrigger: Driver<Void>
        let cmsTrigger: Driver<Void>
        let voipTrigger: Driver<Void>
        let whiteRabbitTrigger: Driver<Void>
        let paperBillTrigger: Driver<Void>
        let logsTrigger: Driver<Void>
        let hiddenTrigger: Driver<Void>
        let frsTrigger: Driver<Void>
        let whiteRabbitHintTrigger: Driver<Void>
    }
    
    struct Output {
        let address: Driver<String>
        let isCmsEnabled: Driver<Bool>
        let areCallsEnabled: Driver<Bool>
        let isWhiteRabbitEnabled: Driver<Bool>
        let arePaperBillsEnabled: Driver<Bool?>
        let areLogsEnabled: Driver<Bool?>
        let areLogsVisibleOnlyForOwner: Driver<Bool?>
        let isFRSEnabled: Driver<Bool?>
        let ringtone: Driver<String>
        let hasDomophone: Driver<Bool>
        let isLoading: Driver<Bool>
        let shouldBlockInteraction: Driver<Bool>
    }
    
}

extension AddressSettingsViewModel: AddressDeletionViewModelDelegate {
    
    func addressDeletionViewModelDidConfirmDeletion(_ viewModel: AddressDeletionViewModel, reason: String) {
        router.rx
            .trigger(.dismiss)
            .asDriverOnErrorJustComplete()
            .flatMapLatest { [weak self] _ -> Driver<CreateIssueResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.issueService
                    .sendDeleteAddressIssue(address: self.address, cliendId: self.clientId, reason: reason)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    self?.apiWrapper.forceUpdateIssues = true
                    
                    NotificationCenter.default.post(.init(name: .addressDeleted, object: nil))
                    
                    self?.router.trigger(.back)
                    
                    self?.alertService
                        .showAlert(
                            title: "Договор удалён",
                            message: nil,
                            priority: 250
                        )
                }
            )
            .disposed(by: disposeBag)
    }
    
}
// swiftlint:enable type_body_length function_body_length cyclomatic_complexity file_length
