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
    private let flatId: String
    private let address: String
    private let router: WeakRouter<SettingsRoute>
    
    init(apiWrapper: APIWrapper, flatId: String, address: String, router: WeakRouter<SettingsRoute>) {
        self.apiWrapper = apiWrapper
        self.flatId = flatId
        self.address = address
        self.router = router
    }
    
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let isCmsEnabledSubject = BehaviorSubject<Bool>(value: false)
        let areCallsEnabledSubject = BehaviorSubject<Bool>(value: false)
        
        apiWrapper
            .getCurrentIntercomState(flatId: flatId)
            .trackActivity(activityTracker)
            .trackError(errorTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .debug()
            .drive(
                onNext: { state in
                    isCmsEnabledSubject.onNext(state.cms)
                    areCallsEnabledSubject.onNext(state.voip)
                }
            )
            .disposed(by: disposeBag)
        
        input.cmsTrigger
            .withLatestFrom(isCmsEnabledSubject.asDriver(onErrorJustReturn: false))
            .flatMapLatest { [weak self] isEnabled -> Driver<IntercomResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .setIntercomCMSState(flatId: self.flatId, isEnabled: !isEnabled)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
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
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .setIntercomVoIPState(flatId: self.flatId, isEnabled: !isEnabled)
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { state in
                    areCallsEnabledSubject.onNext(state.voip)
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
                    guard let self = self else {
                        return
                    }
                    
                    self.router.trigger(.addressDeletion(delegate: self))
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            address: .just(address),
            isCmsEnabled: isCmsEnabledSubject.asDriver(onErrorJustReturn: false),
            areCallsEnabled: areCallsEnabledSubject.asDriver(onErrorJustReturn: false),
            ringtone: .just("Нота"),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension AddressSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let deleteTrigger: Driver<Void>
        let cmsTrigger: Driver<Void>
        let voipTrigger: Driver<Void>
    }
    
    struct Output {
        let address: Driver<String>
        let isCmsEnabled: Driver<Bool>
        let areCallsEnabled: Driver<Bool>
        let ringtone: Driver<String>
        let isLoading: Driver<Bool>
    }
    
}

extension AddressSettingsViewModel: AddressDeletionViewModelDelegate {
    
    func addressDeletionViewModelDidConfirmDeletion(_ viewModel: AddressDeletionViewModel) {
        router.trigger(.back)
    }
    
}
