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
    
    private let clientIdSubject = BehaviorSubject<String?>(value: nil)
    
    init(accessService: AccessService) {
        self.accessService = accessService
    }
    
    func updateClientId(_ clientId: String?) {
        clientIdSubject.onNext(clientId)
    }
    
    func transform(_ input: Input) -> Output {
        let phone: String? = {
            guard let clientPhoneNumber = accessService.clientPhoneNumber else {
                return nil
            }
            
            return "8" + clientPhoneNumber
        }()
        
        let name: String? = {
            guard let clientName = accessService.clientName else {
                return nil
            }
            
            return [clientName.name, clientName.patronymic]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmed
        }()
        
        let chatConfiguration = clientIdSubject.asDriver(onErrorJustReturn: nil)
            .map { clientId -> ChatConfiguration in
                ChatConfiguration(language: nil, clientId: clientId)
            }
            .distinctUntilChanged()
        
        return Output(
            phone: .just(phone),
            name: .just(name),
            chatConfiguration: chatConfiguration
        )
    }
    
}

extension ChatViewModel {
    
    struct Input {
    }
    
    struct Output {
        let phone: Driver<String?>
        let name: Driver<String?>
        let chatConfiguration: Driver<ChatConfiguration>
    }
    
}
