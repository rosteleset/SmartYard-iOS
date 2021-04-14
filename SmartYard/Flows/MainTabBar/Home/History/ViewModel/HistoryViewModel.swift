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
    private let availableDays = PublishSubject<(logs: [APIPlogDay], flatId: Int)>()
    private let logs = PublishSubject<DataSection>()
    private var flatIds: [Int] = []
    private var loadingQueue: [(flatId: Int, identifier: Date)] = [] // Очередь запросов на загрузку (FlatId, Date)
    
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
        
        input.loadDay
            .distinctUntilChanged()
            .flatMap { [weak self] day -> Driver<DataSection?> in
                    
                guard let self = self,
                      let flatId = self.flatIds.first else {
                    return .just(nil)
                }
                
                let lock = NSLock()
                
                lock.lock()
                let isInQueue = self.loadingQueue.first { $0.flatId == flatId && $0.identifier == day }
                
                if isInQueue != nil {
                    lock.unlock()
                    return .just(nil)
                }
                
                self.loadingQueue.append((flatId: flatId, identifier: day))
                lock.unlock()
                
                //TODO: добавить запросы для каждой квартиры в соответствии с фильтром
                
                return self.apiWrapper.plog(flatId: flatId, fromDate: day)
                .trackError(errorTracker)
                .asDriver(onErrorJustReturn: nil)
                    .map { $0 == nil ?  nil : (day: day, items: $0!, flatId: Int(flatId) ) }
            }
            .trackError(errorTracker)
            .ignoreNil()
            .bind(to: self.logs)
            .disposed(by: disposeBag)
        
        // мы знаем только id дома, а логи запрашиваются для id квартиры,
        //поэтому получаем список настроек чтобы понять по id дома идентификатор первой доступной квартиры в данном доме
        //на будущее надо заменить на запросы логов для каждой квартиры.
        apiWrapper.getSettingsAddresses()
            .trackError(errorTracker)
            .trackActivity(activityTracker)
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .flatMap { [weak self] args -> Driver<(logs: PlogDaysResponseData, flatId: Int)?> in
                guard let self = self,
                      let flatId = args.first(where: { $0.houseId == self.houseId })?.flatId else {
                    return .just(nil)
                }
                
                self.flatIds = args.filtered ( {  $0.houseId == self.houseId },  map: { (Int($0.flatId!) ?? -1)  } )
                //TODO: добавить запросы для всех квартир
                
                //запрашиваем список дней, имеющих логи для нашей квартиры
                let result = self.apiWrapper.plogDays(flatId: flatId)
                    .trackError(errorTracker)
                    .map { $0 == nil ?  nil : (logs: $0!, flatId: Int(flatId) ?? -1) }
                    
                return result.asDriver(onErrorJustReturn: nil)
            }
            .trackError(errorTracker)
            .ignoreNil()
            .do(
                onNext: { args in
                    //print(args)
                }
            )
            .bind(to: self.availableDays)
            .disposed(by: disposeBag)
        
        return Output(
            availableDays: availableDays.asDriver(onErrorJustReturn: ([], -1)),
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
        let loadDay: Driver<Date>
    }
    
    struct Output {
        let availableDays: Driver<(logs: [APIPlogDay], flatId: Int)>
        let address: Driver<String?>
        let isLoading: Driver<Bool>
        let plog: Driver<DataSection>
    }
    
}
