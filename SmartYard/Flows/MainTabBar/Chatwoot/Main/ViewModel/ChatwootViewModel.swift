//
//  ChatwootViewModel.swift
//  SmartYard
//
//  Created by devcentra on 20.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//
// swiftlint:disable function_body_length line_length

import Foundation
import RxCocoa
import RxSwift
import XCoordinator

class ChatwootViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    private let automaticMessage = PublishSubject<String>()
    private var loadedMessages = [APIChatwoot]()
    private var minMessageId: Int?
    private var scrollable = true
    private let router: WeakRouter<ChatwootRoute>
    private let chatRow: String?

    private let activityTracker = ActivityTracker()
    private let errorTracker = ErrorTracker()

    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService,
        chatRow: String,
        router: WeakRouter<ChatwootRoute>
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        self.router = router
        self.chatRow = chatRow

        super.init()
        
//        subscribeToChatwootNotifications()
    }
    
    private let messagesChatwootData = BehaviorSubject<[APIChatwoot]>(value: [])

    func transform(_ input: Input) -> Output {
        
        errorTracker.asDriver()
            .catchAuthorizationError { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.logoutHelper.showAuthErrorAlert(
                    activityTracker: self.activityTracker,
                    errorTracker: self.errorTracker,
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

        let activityTracker = ActivityTracker()
        
        let newChatMessageReceivedOnScreen = NotificationCenter.default.rx.notification(.newChatwootMessageReceived)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(input.isViewVisible)
            .isTrue()
            .flatMapLatest { [weak self] _ -> Driver<ChatwootMessagesResponsedata?> in
                guard let self = self else {
                    return .empty()
                }
                self.scrollable = true
                return self.apiWrapper.chatwootinbox(chat: self.chatRow!)
                    .trackActivity(self.activityTracker)
                    .trackError(self.errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }

        let blockingRefresh = Driver
            .merge(
                NotificationCenter.default.rx.notification(.updateChatwootChat).asDriverOnErrorJustComplete().mapToTrue(),
                .just(false)
            )
//            .delay(.milliseconds(800))
            .flatMapLatest { [weak self] _ -> Driver<ChatwootMessagesResponsedata?> in
                guard let self = self else {
                    return .empty()
                }
                self.scrollable = true
                return
                    self.apiWrapper.chatwootinbox(chat: self.chatRow!)
                        .trackActivity(self.activityTracker)
                        .trackError(self.errorTracker)
                        .asDriver(onErrorJustReturn: nil)
            }

        let reloadingFinishedSubject = PublishSubject<Void>()
        let reloadingFinished = reloadingFinishedSubject.asDriverOnErrorJustComplete()

        let nonBlockingRefresh = input.refreshDataTrigger
            .asDriver()
            .delay(.milliseconds(1000))
            .flatMapLatest { [weak self] _ -> Driver<ChatwootMessagesResponsedata?> in
                guard let self = self else {
                    return .empty()
                }
                self.scrollable = true
                if self.minMessageId != nil {
                    self.scrollable = false
                    return self.apiWrapper.chatwootinbox(chat: self.chatRow!, before: self.minMessageId, forceRefresh: true)
                        .trackActivity(self.activityTracker)
                        .trackError(self.errorTracker)
                        .asDriver(onErrorJustReturn: nil)
                }
                return
                    self.apiWrapper.chatwootinbox(chat: self.chatRow!, forceRefresh: true)
                        .trackActivity(self.activityTracker)
                        .trackError(self.errorTracker)
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
                nonBlockingRefresh,
                newChatMessageReceivedOnScreen
            )
            .ignoreNil()
            .do(
                onNext: { [weak self] messages in
                    for msg in messages
                    where self?.loadedMessages.enumerated().first(where: { $0.element.id == msg.id }) == nil {
                        self?.loadedMessages.append(contentsOf: [msg])
                    }
                    self?.minMessageId = self?.loadedMessages.min(by: { am, bm -> Bool in
                        return am.id < bm.id
                    })?.id
                }
            )
            .drive(
                onNext: { [weak self] data in
                    self?.messagesChatwootData.onNext(data)
                }
            )
            .disposed(by: disposeBag)

        input.backTrigger
            .drive(
                onNext: { [weak self] in
                    self?.router.trigger(.main)
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            messages: messagesChatwootData.asDriver(onErrorJustReturn: []),
            isLoading: activityTracker.asDriver(),
            reloadingFinished: reloadingFinished
        )
    }
    
    func sendMessage(image: UIImage?, text: String?) {
        if let image = image {
            apiWrapper.chatwootsendimage(
                chat: self.chatRow!,
                image: image
            )
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { _ in
                    NotificationCenter.default.post(.init(name: .updateChatwootChat, object: nil))
                }
            )
            .disposed(by: disposeBag)
        }
        if let text = text {
            apiWrapper.chatwootsend(
                chat: self.chatRow!,
                message: text
            )
            .asDriver(onErrorJustReturn: nil)
            .ignoreNil()
            .drive(
                onNext: { [weak self] _ in
                    self?.apiWrapper.forseUpdateChatwootChat = true
                    NotificationCenter.default.post(.init(name: .updateChatwootChat, object: nil))
                }
            )
            .disposed(by: disposeBag)
        }
    }
    
    func getAccessService() -> AccessService {
        return accessService
    }

    func isScrollable() -> Bool {
        return scrollable
    }
//    private func subscribeToChatwootNotifications() {
//        NotificationCenter.default.rx.notification(.chatwootRequested)
//            .asDriverOnErrorJustComplete()
//            .drive(
//                onNext: { [weak self] notification in
//                    print(notification)

//                    guard let self = self,
//                        let rawServiceAction = notification.userInfo?[NotificationKeys.serviceActionKey] as? String,
//                        let serviceAction = SettingsServiceAction(rawValue: rawServiceAction),
//                        let rawServiceType = notification.userInfo?[NotificationKeys.serviceTypeKey] as? String,
//                        let serviceType = SettingsServiceType(rawValue: rawServiceType) else {
//                        return
//                    }

//                    let contractName = notification.userInfo?[NotificationKeys.contractNameKey] as? String
//                    let request = serviceAction.request(for: serviceType, contractName: contractName)
//
//                    self.automaticMessage.onNext(request)
//                }
//            )
//            .disposed(by: disposeBag)
//    }
}

extension ChatwootViewModel {
    
    struct Input {
        let isViewVisible: Driver<Bool>
        let refreshDataTrigger: Driver<Void>
        let backTrigger: Driver<Void>
    }
    
    struct Output {
        let messages: Driver<[APIChatwoot]>
        let isLoading: Driver<Bool>
        let reloadingFinished: Driver<Void>
    }

}
