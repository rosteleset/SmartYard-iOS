//
//  ChatViewModel.swift
//  SmartYard
//
//  Created by admin on 31/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxSwift
import RxCocoa
import WebKit
import OnlineChatSdk

class ChatViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    private let pushNotificationService: PushNotificationService
    private let logoutHelper: LogoutHelper
    private let alertService: AlertService
    
    private let automaticMessage = PublishSubject<String>()
    
    init(
        apiWrapper: APIWrapper,
        accessService: AccessService,
        pushNotificationService: PushNotificationService,
        logoutHelper: LogoutHelper,
        alertService: AlertService
    ) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        self.pushNotificationService = pushNotificationService
        self.logoutHelper = logoutHelper
        self.alertService = alertService
        
        super.init()
        
        cleanCache()
        subscribeToChatNotifications()
    }
    
    // swiftlint:disable:next function_body_length
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
                onNext: { error in
                    print(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
        
        let phone: String? = {
            guard let clientPhoneNumber = accessService.clientPhoneNumber else {
                return nil
            }
            
            return "8" + clientPhoneNumber
        }()
        
        let currentName = Driver<APIClientName?>.merge(
            .just(accessService.clientName),
            NotificationCenter.default.rx.notification(.userNameUpdated)
                .map { [weak self] _ in self?.accessService.clientName }
                .asDriver(onErrorJustReturn: nil)
        )
        
        let nameAsString = currentName
            .asDriver(onErrorJustReturn: nil)
            .map { clientName -> String? in
                guard let uClientName = clientName else {
                    return nil
                }
                
                return [uClientName.name, uClientName.patronymic]
                    .compactMap { $0 }
                    .joined(separator: " ")
            }
        
        let hasNetworkBecomeReachable = apiWrapper.isReachableObservable
            .asDriver(onErrorJustReturn: false)
            .distinctUntilChanged()
            .skip(1)
            .isTrue()
            .mapToVoid()
        
        let chatConfiguration = Driver
            .merge(hasNetworkBecomeReachable, .just(()))
            .map { _ -> ChatConfiguration in
                ChatConfiguration(language: nil, clientId: phone?.md5)
            }
        
        // MARK: Если пришло новое сообщение в тот момент, когда мы на этом экране
        
        let newChatMessageReceivedOnScreen = NotificationCenter.default.rx.notification(.newChatMessageReceived)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(input.isViewVisible)
            .isTrue()
            .mapToVoid()
        
        // MARK: Или если мы просто зашли на этот экран - делаем синк
        
        Driver
            .merge(input.viewWillAppearTrigger.mapToVoid(), newChatMessageReceivedOnScreen)
            .flatMapLatest { [weak self] _ -> Driver<Void?> in
                guard let self = self else {
                    return .empty()
                }

                return self.apiWrapper
                    .markChatAsReaded()
                    .trackError(errorTracker)
                    .asDriver(onErrorJustReturn: nil)
            }
            .ignoreNil()
            .drive(
                onNext: { [weak self] in
                    self?.pushNotificationService.deleteAllDeliveredNotifications(withActionType: .chat)
                    self?.pushNotificationService.synchronizeBadgeCount()
                }
            )
            .disposed(by: disposeBag)
        
        // MARK: Если мы не находимся на экране, то новые сообщения не помечаются как доставленные
        // Чтобы пометить их как доставленные, нужно дернуть метод getNewMessages
        
        NotificationCenter.default.rx.notification(.newChatMessageReceived)
            .asDriverOnErrorJustComplete()
            .withLatestFrom(input.isViewVisible)
            .filterFalse()
            .mapToVoid()
            .drive(
                onNext: {
                    guard let md5 = phone?.md5 else {
                        return
                    }
                    
                    ChatApi.getNewMessages(Constants.Chat.token, md5) { result in
                        if result?["error"] != nil {
                            print("error : \(String(describing: result?["error"]))")
                        } else {
                            print("result : \(result.debugDescription)")
                        }
                    }
                }
            )
            .disposed(by: disposeBag)
        
        return Output(
            phone: .just(phone),
            name: nameAsString,
            chatConfiguration: chatConfiguration,
            automaticMessage: automaticMessage.asDriverOnErrorJustComplete(),
            isLoggingOut: activityTracker.asDriver()
        )
    }
    
    private func subscribeToChatNotifications() {
        NotificationCenter.default.rx.notification(.chatRequested)
            .asDriverOnErrorJustComplete()
            .drive(
                onNext: { [weak self] notification in
                    guard let self = self,
                        let rawServiceAction = notification.userInfo?[NotificationKeys.serviceActionKey] as? String,
                        let serviceAction = SettingsServiceAction(rawValue: rawServiceAction),
                        let rawServiceType = notification.userInfo?[NotificationKeys.serviceTypeKey] as? String,
                        let serviceType = SettingsServiceType(rawValue: rawServiceType) else {
                        return
                    }
                    
                    let contractName = notification.userInfo?[NotificationKeys.contractNameKey] as? String
                    let request = serviceAction.request(for: serviceType, contractName: contractName)
                            
                    self.automaticMessage.onNext(request)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func cleanCache() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
}

extension ChatViewModel {
    
    struct Input {
        let viewWillAppearTrigger: Driver<Bool>
        let isViewVisible: Driver<Bool>
    }
    
    struct Output {
        let phone: Driver<String?>
        let name: Driver<String?>
        let chatConfiguration: Driver<ChatConfiguration>
        let automaticMessage: Driver<String>
        let isLoggingOut: Driver<Bool>
    }
    
}
