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
    
    private let router: WeakRouter<SettingsRoute>
    private let address: String
    
    init(router: WeakRouter<SettingsRoute>, address: String) {
        self.router = router
        self.address = address
    }
    
    func transform(_ input: Input) -> Output {
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
        
        return Output(
            address: .just(address),
            shouldDisableOutgoingSound: .just(true),
            shouldAcceptCalls: .just(false),
            ringtone: .just("Нота")
        )
    }
    
}

extension AddressSettingsViewModel {
    
    struct Input {
        let backTrigger: Driver<Void>
        let deleteTrigger: Driver<Void>
    }
    
    struct Output {
        let address: Driver<String>
        let shouldDisableOutgoingSound: Driver<Bool>
        let shouldAcceptCalls: Driver<Bool>
        let ringtone: Driver<String>
    }
    
}

extension AddressSettingsViewModel: AddressDeletionViewModelDelegate {
    
    func addressDeletionViewModelDidConfirmDeletion(_ viewModel: AddressDeletionViewModel) {
        router.trigger(.back)
    }
    
}
