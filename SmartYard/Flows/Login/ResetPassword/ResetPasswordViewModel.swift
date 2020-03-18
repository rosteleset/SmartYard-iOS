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
    private let restoreMethods = BehaviorSubject<[RestoreMethodType]>(value: [])
    
    init(apiWrapper: APIWrapper, router: WeakRouter<HomeRoute>, contractNum: String?) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.contractNum = BehaviorSubject<String?>(value: contractNum)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
    
        let shouldLoadRestoreMethodsTrigger = PublishSubject<Void>()
        
        input.inputContractNum
            .drive(contractNum)
            .disposed(by: disposeBag)
        
        contractNum
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .mapToVoid()
            .drive(shouldLoadRestoreMethodsTrigger)
            .disposed(by: disposeBag)
        
        
        return Output(
            isLoading: activityTracker.asDriver(),
            isEmptyContract: contractNum.map { $0 != nil }.asDriver(onErrorJustReturn: false),
            shouldLoadRestoreMethodsTrigger: shouldLoadRestoreMethodsTrigger.asDriver(onErrorJustReturn: ())
        )
    }
    
}

extension ResetPasswordViewModel {
    
    struct Input {
        let inputContractNum: Driver<String>
        let getRestoreMethodsTrigger: Driver<Void>
        let restoreTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let isEmptyContract: Driver<Bool>
        let shouldLoadRestoreMethodsTrigger: Driver<Void>
    }
    
}
