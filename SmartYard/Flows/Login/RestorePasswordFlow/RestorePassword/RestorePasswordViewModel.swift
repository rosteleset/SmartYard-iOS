//
//  RestorePasswordViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 18.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class RestorePasswordViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<HomeRoute>
    
    private let selectedRestoreMethod = BehaviorSubject<RestoreMethodCellModel?>(value: nil)
    private let restoreMethods = BehaviorSubject<[RestoreMethodCellModel]>(value: [])
    
    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<HomeRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        let contractNum = input.inputContractNum
            .asDriver(onErrorJustReturn: nil)
            .do(
                onNext: { [weak self] _ in
                    self?.restoreMethods.onNext([])
                }
            )
        
        input.getCodeButtonTapped
            .withLatestFrom(contractNum)
            .ignoreNil()
            .withLatestFrom(selectedRestoreMethod.asDriver(onErrorJustReturn: nil)) { ($0, $1) }
            .flatMapLatest { [weak self] args -> Driver<(RestoreMethodCellModel, String)?> in
                let (inputContractNum, selectedMethod) = args
                
                guard let self = self, !inputContractNum.isEmpty, let uSelectedMethod = selectedMethod else {
                    return .just(nil)
                }
                
                return self.apiWrapper.restore(
                        contractNum: inputContractNum,
                        contactId: uSelectedMethod.method.contactId,
                        code: nil
                    )
                    .map {
                        guard $0 != nil else {
                            return nil
                        }
                        
                        return (uSelectedMethod, inputContractNum)
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
                    
                    let (selectedMethodModel, inputContractNum) = args
                    
                    self.router.trigger(
                        .pinCode(contractNum: inputContractNum, selectedRestoreMethod: selectedMethodModel.method)
                    )
                }
            )
            .disposed(by: disposeBag)
    
        input.getRestoreMethodsButtonTapped
            .withLatestFrom(contractNum.asDriver(onErrorJustReturn: nil))
            .ignoreNil()
            .flatMapLatest { [weak self] inputContractNum -> Driver<RestoreRequestResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.restore(contractNum: inputContractNum, contactId: nil, code: nil)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { response in
                    let resetMethodsArr: [RestoreMethod] = response.compactMap { RestoreMethod(apiRestoreData: $0) }
                    
                    self.selectedRestoreMethod.onNext(nil)
                    
                    self.restoreMethods.onNext(
                        resetMethodsArr.map { RestoreMethodCellModel(method: $0, state: .uncheckedActive) }
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
                    
                    self.selectedRestoreMethod.onNext(data.first { $0.state == .checkedActive })
                    
                    self.restoreMethods.onNext(data)
                }
            )
            .disposed(by: disposeBag)
        
        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.back)
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    switch nsError.code {                        
                    case 422, 404:
                        let message = "Введен неверный номер договора"
                        self?.router.trigger(.alert(title: "Ошибка", message: message))
                        
                    default:
                        self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            isLoading: activityTracker.asDriver(),
            restoreMethods: restoreMethods.asDriver(onErrorJustReturn: [])
        )
    }
    
}

extension RestorePasswordViewModel {
    
    struct Input {
        let inputContractNum: Driver<String?>
        let getCodeButtonTapped: Driver<Void>
        let itemStateChanged: Driver<Int?>
        let getRestoreMethodsButtonTapped: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let restoreMethods: Driver<[RestoreMethodCellModel]>
    }
    
}
