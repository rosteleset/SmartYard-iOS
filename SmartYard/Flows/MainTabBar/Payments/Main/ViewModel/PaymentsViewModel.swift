//
//  PaymentsViewModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class PaymentsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<PaymentsRoute>
    
    let activityTracker = ActivityTracker()
    let errorTracker = ErrorTracker()
    
    private let loadedAddressesData = BehaviorSubject<GetAddressListResponseData?>(value: nil)
    
    init(
        apiWrapper: APIWrapper,
        router: WeakRouter<PaymentsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
    }
    
    // swiftlint:disable:next function_body_length
    func transform(_ input: Input) -> Output {
        // MARK: Запрос на обновление, который должен скрывать все происходящее за скелетоном
        
        let interactionBlockingRequestTracker = ActivityTracker()
        
        let blockingRefresh = Driver
            .merge(
                NotificationCenter.default.rx.notification(.addressDeleted).asDriverOnErrorJustComplete().mapToVoid(),
                NotificationCenter.default.rx.notification(.addressAdded).asDriverOnErrorJustComplete().mapToVoid(),
                .just(())
            )
            .flatMapLatest { [weak self] _ -> Driver<GetAddressListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.apiWrapper.getAddressList()
                        .trackActivity(interactionBlockingRequestTracker)
                        .trackError(self.errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }
        
        // MARK: Запрос на обновление, который вызван рефреш контролом
        
        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()
        
        let nonBlockingRefresh = input.refreshDataTrigger
            .asDriver()
            .delay(.milliseconds(1000))
            .flatMapLatest { [weak self] _ -> Driver<GetAddressListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.apiWrapper.getAddressList()
                        .trackError(self.errorTracker)
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
            .drive(loadedAddressesData)
            .disposed(by: disposeBag)
        
        let items = loadedAddressesData.asDriver(onErrorJustReturn: nil)
            .map { [weak self] data -> [PaymentAddressItem] in
                guard let self = self,
                    let addresses = data
                else {
                    return []
                }
                
                return self.createItems(addresses: addresses)
            }
        
        errorTracker.asDriver()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            itemModels: items,
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished,
            shouldBlockInteraction: interactionBlockingRequestTracker.asDriver()
        )
    }
    
    func createItems(addresses: GetAddressListResponseData) -> [PaymentAddressItem] {
        return addresses.map {
            PaymentAddressItem(id: $0.houseId, address: $0.address)
        }
    }
    
}

extension PaymentsViewModel {
    
    struct Input {
        let itemSelected: Driver<IndexPath>
        let refreshDataTrigger: Driver<Void>
    }
    
    struct Output {
        let itemModels: Driver<[PaymentAddressItem]>
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let shouldBlockInteraction: Driver<Bool>
    }
    
}
