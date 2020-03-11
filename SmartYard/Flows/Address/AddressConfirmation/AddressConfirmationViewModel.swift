//
//  AddressConfirmationViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class AddressConfirmationViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    private let apiWrapper: APIWrapper
    private let issueService: IssueService
    
    init(
        router: WeakRouter<HomeRoute>,
        apiWrapper: APIWrapper,
        issueService: IssueService
    ) {
        self.router = router
        self.apiWrapper = apiWrapper
        self.issueService = issueService
    }
    
    func transform(_ input: Input) -> Output {
        input.confirmByCourierTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
        
        input.confirmInOfficeTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension AddressConfirmationViewModel {
    
    struct Input {
        let confirmByCourierTapped: Driver<Void>
        let confirmInOfficeTrigger: Driver<Void>
    }
    
    struct Output {
        
    }
    
}
