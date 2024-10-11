//
//  ActivateLimitViewModel.swift
//  SmartYard
//
//  Created by Разработчик CENTRA on 17.09.2024.
//  Copyright © 2024 Layka. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCoordinator
import UIKit

class ActivateLimitViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let contract: ContractFaceObject
    private var router: WeakRouter<HomePayRoute>
    
    private let contractId = BehaviorSubject<String?>(value: nil)

    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()
    
    init(
        accessService: AccessService,
        apiWrapper: APIWrapper,
        contract: ContractFaceObject,
        router: WeakRouter<HomePayRoute>
    ) {
        self.accessService = accessService
        self.apiWrapper = apiWrapper
        self.contract = contract
        self.router = router
        self.contractId.onNext(contract.clientId)
    }

    func transform(input: Input) {
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    let nsError = error as NSError
                    
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        input.closeButtonTapped
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
        
        input.activateButtonTapped
            .withLatestFrom(contractId.asDriver(onErrorJustReturn: nil))
            .flatMapLatest { [weak self] contractId -> Driver<String?> in
                guard let self = self, let contractId = contractId else {
                    return .empty()
                }
                
                return self.apiWrapper
                    .activateLimit(contractId: contractId)
                    .trackError(errorTracker)
                    .trackActivity(activityTracker)
                    .map {
                        guard let response = $0 else {
                            return nil
                        }
                        return contractId
                    }
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    NotificationCenter.default.post(name: .addressNeedUpdate, object: nil)
                    self?.router.trigger(.dismiss)
                }
            )
            .disposed(by: disposeBag)
    }
}

extension ActivateLimitViewModel {
    
    struct Input {
        let closeButtonTapped: Driver<Void>
        let activateButtonTapped: Driver<Void>
    }
    
}
