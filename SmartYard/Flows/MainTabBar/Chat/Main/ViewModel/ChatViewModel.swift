//
//  ChatViewModel.swift
//  SmartYard
//
//  Created by admin on 31/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxSwift
import RxCocoa

class ChatViewModel: BaseViewModel {
    
    private let apiWrapper: APIWrapper
    private let accessService: AccessService
    
    private let automaticMessage = PublishSubject<String>()
    
    init(apiWrapper: APIWrapper, accessService: AccessService) {
        self.apiWrapper = apiWrapper
        self.accessService = accessService
        
        super.init()
        
        subscribeToChatNotifications()
    }
    
    func transform(_ input: Input) -> Output {
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
        
        return Output(
            phone: .just(phone),
            name: nameAsString,
            chatConfiguration: chatConfiguration,
            automaticMessage: automaticMessage.asDriverOnErrorJustComplete()
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
    
}

extension ChatViewModel {
    
    struct Input {
    }
    
    struct Output {
        let phone: Driver<String?>
        let name: Driver<String?>
        let chatConfiguration: Driver<ChatConfiguration>
        let automaticMessage: Driver<String>
    }
    
}
