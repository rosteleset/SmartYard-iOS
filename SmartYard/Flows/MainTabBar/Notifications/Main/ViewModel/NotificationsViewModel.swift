//
//  NotificationsViewModel.swift
//  SmartYard
//
//  Created by admin on 23/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa
import XCoordinator

class NotificationsViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let pushNotificationService: PushNotificationService
    
    init(apiWrapper: APIWrapper, pushNotificationService: PushNotificationService) {
        self.apiWrapper = apiWrapper
        self.pushNotificationService = pushNotificationService
    }
    
    func transform(_ input: Input) -> Output {
        let errorTracker = ErrorTracker()
        let activityTracker = ActivityTracker()
        
        let reloadHtmlCodeTrigger = PublishSubject<Void>()
        
        let inboxResponseSubject = BehaviorSubject<InboxResponseData?>(value: nil)
        
        Driver
            .merge(
                reloadHtmlCodeTrigger.asDriverOnErrorJustComplete(),
                .just(())
            )
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
                    self?.pushNotificationService.markAllMessagesAsRead()
                    
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
    }
    
    struct Output {
        let inboxResponse: Driver<InboxResponseData?>
        let isLoading: Driver<Bool>
    }
    
}
