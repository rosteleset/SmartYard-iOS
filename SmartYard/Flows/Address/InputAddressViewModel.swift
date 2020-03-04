//
//  InputAddressViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 10.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa

class InputAddressViewModel: BaseViewModel {
    
    private let router: WeakRouter<HomeRoute>
    
    init(router: WeakRouter<HomeRoute>) {
        self.router = router
    }
    
    func transform(input: Input) -> Output {
        input.qrCodeTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        input.checkServicesTapped
            .drive(
                onNext: {
                    // TODO
                }
            )
            .disposed(by: disposeBag)
        
        return Output()
    }
    
}

extension InputAddressViewModel {
    
    struct Input {
        let qrCodeTapped: Driver<Void>
        let checkServicesTapped: Driver<Void>
    }
    
    struct Output {
        
    }
    
}

