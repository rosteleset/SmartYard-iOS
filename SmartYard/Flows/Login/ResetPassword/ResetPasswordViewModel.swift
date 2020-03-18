//
//  ResetPasswordViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ResetPasswordViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    private let contractNum: String
    
    init(apiWrapper: APIWrapper, router: WeakRouter<HomeRoute>, contractNum: String) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.contractNum = contractNum
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        return Output(
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension ResetPasswordViewModel {
    
    struct Input {
        let inputContractNum: Driver<String>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
    }
    
}
