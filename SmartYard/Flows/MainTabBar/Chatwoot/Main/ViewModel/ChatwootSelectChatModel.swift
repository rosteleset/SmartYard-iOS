//
//  ChatwootSelectChatModel.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ChatwootSelectChatModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let router: WeakRouter<ChatwootRoute>
    private let accessService: AccessService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService

    private let items = BehaviorSubject<[APIChat]>(value: [])

    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<ChatwootRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.router = router
        self.accessService = accessService
        self.logoutHelper = logoutHelper
        self.alertService = alertService

        super.init()
        
    }
    
    func transform(_ input: Input) -> Output {
        let activityTracker = ActivityTracker()
        let errorTracker = ErrorTracker()
        
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: activityTracker,
                    errorTracker: errorTracker,
                    disposeBag: self.disposeBag
                )
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] error in
                    self?.router.trigger(.alert(title: "Ошибка", message: error.localizedDescription))
                }
            )
            .disposed(by: disposeBag)
        
        input.itemSelected
            .withLatestFrom(items.asDriver(onErrorJustReturn: [APIChat]())) { ($0, $1) }
            .drive(
                onNext: { [weak self] args in
                    let (indexPath, items) = args
                    self?.router.trigger(
                        .personalchat(
                            index: indexPath.row,
                            items: items
                        )
                    )
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Запрос на обновление, который должен скрывать все происходящее за скелетоном
        let interactionBlockingRequestTracker = ActivityTracker()
        
        let blockingRefresh = Driver
            .merge(
//                NotificationCenter.default.rx.notification(.addressDeleted).asDriverOnErrorJustComplete().mapToVoid(),
//                NotificationCenter.default.rx.notification(.addressAdded).asDriverOnErrorJustComplete().mapToVoid(),
                .just(())
            )
            .flatMapLatest { [weak self] _ -> Driver<ChatwootGetChatListResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return
                    self.apiWrapper.chatwootlist()
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
            .flatMapLatest { [weak self] _ -> Driver<ChatwootGetChatListResponseData?> in
                guard let self = self else {
                    return .empty()
                }

                return
                    self.apiWrapper.chatwootlist(forceRefresh: true)
                        .trackError(errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }
            .do(
                onNext: { _ in
                    reloadingFinishedSubject.onNext(())
                }
            )
        
        Driver
            .merge(
                blockingRefresh,
                nonBlockingRefresh
            )
            .ignoreNil()
            .drive(
                onNext: { [weak self] data in
                    self?.items.onNext(data)
            
                    if data.count == .zero {
                        self?.router.trigger(
                            .alert(
                                title: "Нет доступных чатов",
                                message: ""
                            )
                        )
                    }
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

extension ChatwootSelectChatModel {
    
    struct Input {
        let itemSelected: Driver<IndexPath>
        let refreshDataTrigger: Driver<Void>
    }
    
    struct Output {
        let itemModels: Driver<[APIChat]>
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
        let shouldBlockInteraction: Driver<Bool>
    }

}
