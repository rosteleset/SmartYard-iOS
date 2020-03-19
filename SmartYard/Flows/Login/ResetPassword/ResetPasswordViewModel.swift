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
    
    private let contractNum: BehaviorSubject<String?>
    private let resetMethods: BehaviorSubject<[ResetMethodType]>
    
    init(apiWrapper: APIWrapper, router: WeakRouter<HomeRoute>, contractNum: String?, resetMethods: [ResetMethodType]) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.contractNum = BehaviorSubject<String?>(value: contractNum)
        self.resetMethods = BehaviorSubject<[ResetMethodType]>(value: resetMethods)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
    
        let shouldLoadResetMethodsTrigger = PublishSubject<Void>()
        
        input.inputContractNum
            .drive(contractNum)
            .disposed(by: disposeBag)
        
        contractNum
            .map { $0.isNilOrEmpty }
            .asDriver(onErrorJustReturn: false)
            .mapToVoid()
            .drive(shouldLoadResetMethodsTrigger)
            .disposed(by: disposeBag)
        
        contractNum
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .mapToVoid()
            .drive(shouldLoadResetMethodsTrigger)
            .disposed(by: disposeBag)

        return Output(
            isLoading: activityTracker.asDriver(),
            shouldLoadResetMethodsTrigger: shouldLoadResetMethodsTrigger.asDriver(onErrorJustReturn: ()),
            resetMethods: resetMethods.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension ResetPasswordViewModel {
    
    struct Input {
        let inputContractNum: Driver<String?>
        let actionTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let shouldLoadResetMethodsTrigger: Driver<Void>
        let resetMethods: Driver<[ResetMethodType]>
    }
    
}
