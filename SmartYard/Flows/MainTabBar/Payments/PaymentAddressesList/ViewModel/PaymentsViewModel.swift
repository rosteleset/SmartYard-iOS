//
//  PaymentsViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class PaymentsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<PaymentsRoute>
    
    private let items = BehaviorSubject<[APIPaymentsListAddress]>(value: [])
    
    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<PaymentsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        input.itemSelected
            .withLatestFrom(items.asDriver(onErrorJustReturn: [APIPaymentsListAddress]())) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (indexPath, items) = args
                    self?.router.trigger(
                        .contractPay(
                            address: items[indexPath.row].address,
                            items: items[indexPath.row].accounts
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Запрос на обновление, который должен скрывать все происходящее за скелетоном
        let interactionBlockingRequestTracker = ActivityTracker()
        
        let blockingRefresh = Driver
            .merge(
                NotificationCenter.default.rx.notification(.addressDeleted).asDriverOnErrorJustComplete().mapToVoid(),
                NotificationCenter.default.rx.notification(.addressAdded).asDriverOnErrorJustComplete().mapToVoid(),
                NotificationCenter.default.rx.notification(.paymentCompleted).asDriverOnErrorJustComplete().mapToVoid(),
                .just(())
            )
            .flatMapLatest { [weak self] _ -> Driver<GetPaymentsListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.apiWrapper.getPaymentsList()
                        .trackActivity(interactionBlockingRequestTracker)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }
        
        // MARK: Запрос на обновление, который вызван рефреш контролом
        
        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()
        
        let nonBlockingRefresh = input.refreshDataTrigger
            .asDriver()
            .delay(.milliseconds(1000))
            .flatMapLatest { [weak self] _ -> Driver<GetPaymentsListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.apiWrapper.getPaymentsList(forceRefresh: true)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }
            .do(
                onNext: { _ in
                    reloadingFinishedSubject.onNext(())
                }
            )
        
        Driver
            .merge(blockingRefresh, nonBlockingRefresh)
            .ignoreNil()
            .drive(
                onNext: { [weak self] data in
                    self?.items.onNext(data)
                }
            )
            .disposed(by: disposeBag)
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            itemModels: items.asDriver(onErrorJustReturn: []),
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished,
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver()
        )
    }
    
}

extension PaymentsViewModel {
    
    struct Input {
        let itemSelected: Driver<IndexPath>
        let refreshDataTrigger: Driver<Void>
    }
    
    struct Output {
        let itemModels: Driver<[APIPaymentsListAddress]>
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let shouldBlockInteraction: Driver<Bool>
    }
    
}
