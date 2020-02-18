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
    
    private let router: WeakRouter<AppRoute>
    private let allowedPersonType: PersonType
    
    private let phoneTextSubject = PublishSubject<String?>()
    
    private weak var delegate: NewAllowedPersonViewModelDelegate?
    
    init(
        router: WeakRouter<AppRoute>,
        delegate: NewAllowedPersonViewModelDelegate,
        allowedPersonType: PersonType
    ) {
        self.router = router
        self.allowedPersonType = allowedPersonType
        self.delegate = delegate
    }
    
    func transform(_ input: Input) -> Output {
        input.inputPhoneTextTrigger
            .drive(
                onNext: { [weak self] phoneNumber in
                    self?.phoneTextSubject.onNext(phoneNumber)
                }
            )
            .disposed(by: disposeBag)
        
        input.closeTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        Driver
            .zip(
                input.addAccessTrigger,
                phoneTextSubject.asDriver(onErrorJustReturn: "")
            )
            .drive(
                onNext: { [weak self] args in
                    let (_, phone) = args
                    
                    guard let self = self, let phoneNumber = phone else {
                        return
                    }
                    
                    let allowedPerson = AllowedPerson(displayedName: nil, phoneNumber: phoneNumber, logoImage: nil)
                    
                    switch self.allowedPersonType {
                    case .permanent:
                        self.delegate?.newAllowedPersonViewModelDidAddNewPermanent(
                            self,
                            allowedPerson: allowedPerson
                        )
                        
                    case .temporary:
                        self.delegate?.newAllowedPersonViewModelDidAddNewTemp(
                            self,
                            allowedPerson: allowedPerson
                        )
                    }
                    
                    self.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.selectFromContactTrigger
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension NewAllowedPersonViewModel {
    
    struct Input {
        let closeTrigger: Driver<Void>
        let selectFromContactTrigger: Driver<Void>
        let addAccessTrigger: Driver<Void>
        let inputPhoneTextTrigger: Driver<String>
    }
    
    struct Output {
        
    }
    
}
