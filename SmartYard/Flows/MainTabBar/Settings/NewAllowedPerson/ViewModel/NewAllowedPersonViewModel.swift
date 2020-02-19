//
//  NewAllowedPersonViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 17.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

protocol NewAllowedPersonViewModelDelegate: AnyObject {
    
    func newAllowedPersonViewModelDidAddNewTemp(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    )
    
    func newAllowedPersonViewModelDidAddNewPermanent(
        _ viewModel: NewAllowedPersonViewModel,
        allowedPerson: AllowedPerson
    )
    
}

class NewAllowedPersonViewModel: BaseViewModel {
    
    private let router: WeakRouter<SettingsRoute>
    private let allowedPersonType: AllowedPersonType

    private let newAllowedPersonSubject = PublishSubject<AllowedPerson?>()
    
    private weak var delegate: NewAllowedPersonViewModelDelegate?
    
    init(
        router: WeakRouter<SettingsRoute>,
        delegate: NewAllowedPersonViewModelDelegate,
        allowedPersonType: AllowedPersonType
    ) {
        self.router = router
        self.allowedPersonType = allowedPersonType
        self.delegate = delegate
    }
    
    func transform(_ input: Input) -> Output {
        input.closeTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)

        input.addAccessTrigger
            .drive(
                onNext: { [weak self] newAllowedPerson in
                    guard let self = self, let person = newAllowedPerson else {
                        return
                    }
                    
                    switch self.allowedPersonType {
                    case .permanent:
                        self.delegate?.newAllowedPersonViewModelDidAddNewPermanent(
                            self,
                            allowedPerson: person
                        )
                        
                    case .temporary:
                        self.delegate?.newAllowedPersonViewModelDidAddNewTemp(
                            self,
                            allowedPerson: person
                        )
                    }
                    
                    self.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension NewAllowedPersonViewModel {
    
    struct Input {
        let closeTrigger: Driver<Void>
        let addAccessTrigger: Driver<AllowedPerson?>
    }
    
    struct Output {
        
    }
    
}
