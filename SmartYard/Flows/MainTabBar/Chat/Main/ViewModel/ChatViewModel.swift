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
    
    init(accessService: AccessService) {
        self.accessService = accessService
    }
    
    func transform(_ input: Input) -> Output {
        let phone: String? = {
            guard let clientPhoneNumber = accessService.clientPhoneNumber else {
                return nil
            }
            
            return "8" + clientPhoneNumber
        }()
        
        let chatConfiguration = Driver<ChatConfiguration>.merge(
            .just(ChatConfiguration(language: nil, clientId: nil)),
            NotificationCenter.default.rx.notification(.chatRequested)
                .asDriverOnErrorJustComplete()
                .flatMap { notification -> Driver<ChatConfiguration> in
                    guard let clientId = notification.userInfo?[NotificationKeys.clientIdKey] as? String else {
                        return .empty()
                    }
                    
                    return .just(ChatConfiguration(language: nil, clientId: clientId))
                }
        )
        
        return Output(
            phone: .just(phone),
            chatConfiguration: chatConfiguration
        )
    }
    
}

extension ChatViewModel {
    
    struct Input {
    }
    
    struct Output {
        let phone: Driver<String?>
        let chatConfiguration: Driver<ChatConfiguration>
    }
    
}
