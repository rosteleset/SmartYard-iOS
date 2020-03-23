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
    private let selectedContactId = BehaviorSubject<String?>(value: nil)
    
    private let resetMethods: BehaviorSubject<[ResetMethodModel]>
    
    init(apiWrapper: APIWrapper, router: WeakRouter<HomeRoute>, contractNum: String?, resetMethods: [ResetMethodType]) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.contractNum = BehaviorSubject<String?>(value: contractNum)
        
        let resetModels = resetMethods.map { ResetMethodModel(type: $0, state: .uncheckedActive) }
        self.resetMethods = BehaviorSubject<[ResetMethodModel]>(value: resetModels)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.inputContractNum
            .do(
                onNext: { [weak self] _ in
                    self?.resetMethods.onNext([])
                }
            )
            .drive(contractNum)
            .disposed(by: disposeBag)
        
        input.actionTrigger
            .withLatestFrom(contractNum.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .withLatestFrom(selectedContactId.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(RestoreRequestResponseData?, String?)?> in
                let (contractNum, contactId) = args
                
                guard let self = self, !contractNum.isEmpty else {
                    return .just(nil)
                }

                return self.apiWrapper.restore(contractNum: contractNum, contractId: contactId, code: nil)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        
                        return (response, contactId)
                    }
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] args in
                    guard let self = self else {
                        return
                    }
                    
                    let (response, contactId) = args
                    
                    guard contactId.isNilOrEmpty else {
                        self.router.trigger(.)
                        return
                    }
                    
                    let resetMethodsArr = response?.compactMap { response in
                        ResetMethodType(rawValue: response.type)
                    } ?? []
                    
                    self.resetMethods.onNext(
                        resetMethodsArr.map { ResetMethodModel(type: $0, state: .uncheckedActive) }
                    )
                }
            )
            .disposed(by: disposeBag)

        input.itemStateChanged
            .drive(
                onNext: { [weak self] index in
                    guard let self = self,
                        let index = index,
                        var data = try? self.resetMethods.value()
                        else {
                            return
                    }
                    
                    data.enumerated().forEach { offset, _ in
                        if offset == index {
                            data[offset].toogleState()
                        } else {
                            data[offset].setUncheckedState()
                        }
                    }
                    
                    self.resetMethods.onNext(data)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            resetMethods: resetMethods.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension ResetPasswordViewModel {
    
    struct Input {
        let inputContractNum: Driver<String?>
        let actionTrigger: Driver<Void>
        let itemStateChanged: Driver<Int?>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let resetMethods: Driver<[ResetMethodModel]>
    }
    
}
