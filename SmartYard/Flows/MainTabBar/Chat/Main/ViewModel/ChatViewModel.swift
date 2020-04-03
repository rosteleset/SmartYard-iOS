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
    
    private let accessService: AccessService
    
    private let automaticMessage = PublishSubject<String>()
    
    init(accessService: AccessService) {
        self.accessService = accessService
        
        super.init()
        
        subscribeToChatNotifications()
    }
    
    func sendAutomaticMessage(action: SettingsServiceAction, service: SettingsServiceType, clientId: String?) {
        let request = action.request(for: service, clientId: clientId)
        
        let test = "Тестовое сообщение из мобильного клиента \"Lanta\". "
        
        automaticMessage.onNext(test + request)
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
        
        let chatConfiguration = ChatConfiguration(language: nil, clientId: phone?.md5)
        
        return Output(
            phone: .just(phone),
            name: nameAsString,
            chatConfiguration: .just(chatConfiguration),
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
                    
                    let clientId = notification.userInfo?[NotificationKeys.clientIdKey] as? String
                    
                    self.sendAutomaticMessage(action: serviceAction, service: serviceType, clientId: clientId)
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
