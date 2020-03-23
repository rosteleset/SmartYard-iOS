//
//  AddressDeletionViewModel.swift
//  SmartYard
//
//  Created by admin on 14/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

protocol AddressDeletionViewModelDelegate: AnyObject {
    
    func addressDeletionViewModelDidConfirmDeletion(_ viewModel: AddressDeletionViewModel, reason: String)
    
}

class AddressDeletionViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    
    private weak var delegate: AddressDeletionViewModelDelegate?
    
    init(router: WeakRouter<SettingsRoute>, delegate: AddressDeletionViewModelDelegate) {
        self.router = router
        self.delegate = delegate
    }
    
    func transform(_ input: Input) -> Output {
         let isAbleToDelete: Driver<Bool> = Driver
            .combineLatest(input.deletionReason, input.customDescription)
            .map { args in
                let (reason, customDescription) = args
                
                switch reason {
                case .other: return !(customDescription?.trimmed).isNilOrEmpty
                default: return true
                }
            }
        
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
                    let (deletionReason, customDescription) = args
                    
                    let reasonString: String? = {
                        switch deletionReason {
                        case .wantToBreakTheContract: return "Хочу расторгнуть договор"
                        case .other: return customDescription?.trimmed
                        }
                    }()
                    
                    guard let self = self, let uReason = reasonString, !uReason.isEmpty else {
                        return
                    }
                    
                    self.delegate?.addressDeletionViewModelDidConfirmDeletion(self, reason: uReason)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(isAbleToDelete: isAbleToDelete)
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
        let isAbleToDelete: Driver<Bool>
    }
    
}
