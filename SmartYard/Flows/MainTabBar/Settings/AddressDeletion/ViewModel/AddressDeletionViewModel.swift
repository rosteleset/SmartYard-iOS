//
//  AddressDeletionViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

protocol AddressDeletionViewModelDelegate: AnyObject {
    
    func addressDeletionViewModelDidConfirmDeletion(_ viewModel: AddressDeletionViewModel, reason: String)
    
}

final class AddressDeletionViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private weak var delegate: AddressDeletionViewModelDelegate?
    
    init(router: WeakRouter<SettingsRoute>, delegate: AddressDeletionViewModelDelegate) {
        self.router = router
        self.delegate = delegate
    }
    
    func transform(_ input: Input) -> Output {
        input.cancelTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.deleteTrigger
            .withLatestFrom(input.deletionReason)
            .withLatestFrom(input.customDescription) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (deletionReason, customDescription) = args
                    
                    let reason: String = {
                        switch deletionReason {
                        case .wantToBreakTheContract:
                            return NSLocalizedString("I want to cancel my contract", comment: "")
                            
                        case .other:
                            let trimmed = (customDescription ?? "").trimmed
                            
                            return trimmed.isEmpty ? NSLocalizedString("Customer didn't provide a reason", comment: "") : trimmed
                        }
                    }()
                    
                    self.delegate?.addressDeletionViewModelDidConfirmDeletion(self, reason: reason)
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension AddressDeletionViewModel {
    
    struct Input {
        let cancelTrigger: Driver<Void>
        let deleteTrigger: Driver<Void>
        let deletionReason: Driver<AddressDeletionReason>
        let customDescription: Driver<String?>
    }
    
    struct Output {
    }
    
}
