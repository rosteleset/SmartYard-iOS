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
    
    private let selectedContact = BehaviorSubject<RestoreMethodModel?>(value: nil)
    
    private let restoreMethods: BehaviorSubject<[RestoreMethodModel]>
    
    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<HomeRoute>,
        contractNum: String?,
        restoreMethods: [RestoreMethodType]
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.contractNum = BehaviorSubject<String?>(value: contractNum)
        
        let restoreModels = restoreMethods.map { RestoreMethodModel(type: $0, state: .uncheckedActive) }
        self.restoreMethods = BehaviorSubject<[RestoreMethodModel]>(value: restoreModels)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.inputContractNum
            .do(
                onNext: { [weak self] _ in
                    self?.restoreMethods.onNext([])
                }
            )
            .drive(contractNum)
            .disposed(by: disposeBag)
        
        input.actionTrigger
            .withLatestFrom(contractNum.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .withLatestFrom(selectedContact.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(RestoreRequestResponseData?, String?)?> in
                let (contractNum, contact) = args
                
                guard let self = self, !contractNum.isEmpty else {
                    return .just(nil)
                }

                return self.apiWrapper.restore(contractNum: contractNum, contactId: contact?.type.contactId, code: nil)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        
                        return (response, contact?.type.contactId)
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
                        self.router.trigger(.pinCode(phoneNumber: response?.first?.contact ?? ""))
                        return
                    }
                    
                    let resetMethodsArr: [RestoreMethodType] = response?.compactMap { response in
                        guard let id = response.id, let contact = response.contact else {
                            return nil
                        }
                        
                        return RestoreMethodType(rawValue: response.type, contactId: id, contact: contact)
                    } ?? []
                    
                    self.restoreMethods.onNext(
                        resetMethodsArr.map { RestoreMethodModel(type: $0, state: .uncheckedActive) }
                    )
                }
            )
            .disposed(by: disposeBag)

        input.itemStateChanged
            .drive(
                onNext: { [weak self] index in
                    guard let self = self,
                        let index = index,
                        var data = try? self.restoreMethods.value()
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
                    
                    self.selectedContact.onNext(data.first { $0.state == .checkedActive })
                    
                    self.restoreMethods.onNext(data)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            resetMethods: restoreMethods.asDriver(onErrorJustReturn: [])
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
        let resetMethods: Driver<[RestoreMethodModel]>
    }
    
}
