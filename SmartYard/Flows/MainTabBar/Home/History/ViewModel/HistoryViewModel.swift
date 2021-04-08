//
//  YardMapViewModel.swift
//  SmartYard
//
//  Created by Mad Brains on 27.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import XCoordinator
import RxSwift
import RxCocoa
import CoreLocation

class HistoryViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let houseId: String
    private let router: WeakRouter<HomeRoute>
    
    private let address: BehaviorSubject<String?>
    private let availableDays = PublishSubject<[APIPlogDays]>()
    private let logs = PublishSubject<(forDate: Date, data: [APIPlog])>()
    
    init(apiWrapper: APIWrapper, houseId: String, address: String, router: WeakRouter<HomeRoute>) {
        self.apiWrapper = apiWrapper
        self.houseId = houseId
        self.router = router
        
        self.address = BehaviorSubject<String?>(value: address)
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
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
        
        apiWrapper.getSettingsAddresses()
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .flatMap { [weak self] args -> SharedSequence<DriverSharingStrategy, PlogDaysResponseData?> in
                guard let self = self,
                      let flatId = args.first(where: { $0.houseId == self.houseId })?.flatId else {
                    return .just([])
                }
                
                return self.apiWrapper.plogDays(flatId: flatId)
                            .asDriver(onErrorJustReturn: nil)
            }
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .drive(
                onNext: { [weak self] data in
                    
                    guard let self = self,
                          let data = data else {
                        return
                    }
                    self.availableDays.onNext(data)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            availableDays: availableDays.asDriver(onErrorJustReturn: []),
            address: address.asDriverOnErrorJustComplete(),
            isLoading: activityTracker.asDriver(),
            plog: logs.asDriverOnErrorJustComplete()
        )
    }
    
}

extension HistoryViewModel {
    
    struct Input {
        let itemSelected: Driver<Int>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let availableDays: Driver<[APIPlogDays]>
        let address: Driver<String?>
        let isLoading: Driver<Bool>
        let plog: Driver<(forDate: Date, data: [APIPlog])>
    }
    
}
