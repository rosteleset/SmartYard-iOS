//
//  OnboardingViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import XCoordinator
import RxCocoa
import RxSwift

class OnboardingViewModel: BaseViewModel {
    
    private let router: WeakRouter<AppRoute>
    private let accessService: AccessService
    
    init(router: WeakRouter<AppRoute>, accessService: AccessService) {
        self.router = router
        self.accessService = accessService
    }
    
    func transform(input: Input) -> Output {
        Driver
            .merge(
                input.letsStartTapped,
                input.skipTapped
            )
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.selectProvider)
                    self?.accessService.appState = .selectProvider
                }
        )
            .disposed(by: disposeBag)
        
        return Output()
    }
}

extension OnboardingViewModel {
    
    struct Input {
        let skipTapped: Driver<Void>
        let letsStartTapped: Driver<Void>
    }
    
    struct Output { }
    
}
