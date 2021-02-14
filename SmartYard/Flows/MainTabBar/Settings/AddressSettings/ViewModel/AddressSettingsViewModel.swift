//
//  AddressSettingsViewModel.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

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
        let arePaperBillsEnabledSubject = BehaviorSubject<Bool?>(value: nil)
        
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
                        arePaperBillsEnabledSubject.onNext(state.paperBill)
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
        
        return Output(
            address: .just(address),
            isCmsEnabled: isCmsEnabledSubject.asDriver(onErrorJustReturn: false),
            areCallsEnabled: areCallsEnabledSubject.asDriver(onErrorJustReturn: false),
            arePaperBillsEnabled: arePaperBillsEnabledSubject.asDriver(onErrorJustReturn: false),
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
        let paperBillTrigger: Driver<Void>
    }
    
    struct Output {
        let address: Driver<String>
        let isCmsEnabled: Driver<Bool>
        let areCallsEnabled: Driver<Bool>
        let arePaperBillsEnabled: Driver<Bool?>
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
                    .sendDeleteAddressIssue(address: self.address, reason: reason)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    NotificationCenter.default.post(.init(name: .addressDeleted, object: nil))
                    
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
