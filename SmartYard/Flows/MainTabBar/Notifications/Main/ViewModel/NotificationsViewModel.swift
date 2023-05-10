//
//  NotificationsViewModel.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length

import RxSwift
import RxCocoa
import XCoordinator

class NotificationsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    private let router: WeakRouter<NotificationsRoute>
    
    init(
        apiWrapper: APIWrapper,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        router: WeakRouter<NotificationsRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
    }
    
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        
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
        
        input.shareUrlTrigger
            .drive(
                onNext: { [weak self] url in
                    self?.router.trigger(.share(items: [url]))
                }
            )
            .disposed(by: disposeBag)
        
        let inboxResponseSubject = BehaviorSubject<InboxResponseData?>(value: nil)
        
        let newMessageRefresh = NotificationCenter.default.rx.notification(.newInboxMessageReceived)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(input.isViewVisible)
            .isTrue()
            .mapToVoid()
        
        let hasNetworkBecomeReachable = apiWrapper.isReachableObservable
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .skip(1)
            .isTrue()
            .withLatestFrom(input.isViewVisible)
            .isTrue()
            .mapToVoid()
            
        Driver
            .merge(input.viewWillAppearTrigger.mapToVoid(), newMessageRefresh, hasNetworkBecomeReachable)
            .flatMapLatest { [weak self] _ -> Driver<InboxResponseData?> in
                guard let self = self else {
                    return .empty()
                }
                
                return self.apiWrapper.inbox()
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] response in
                    self?.pushNotificationService.deleteAllDeliveredNotifications(withActionType: .inbox)
                    self?.pushNotificationService.synchronizeBadgeCount()
                    
                    inboxResponseSubject.onNext(response)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            inboxResponse: inboxResponseSubject.asDriver(onErrorJustReturn: nil),
            isLoading: activityTracker.asDriver()
        )
    }
    
}

extension NotificationsViewModel {
    
    struct Input {
        let viewWillAppearTrigger: Driver<Bool>
        let isViewVisible: Driver<Bool>
        let shareUrlTrigger: Driver<URL>
    }
    
    struct Output {
        let inboxResponse: Driver<InboxResponseData?>
        let isLoading: Driver<Bool>
    }
    
}
