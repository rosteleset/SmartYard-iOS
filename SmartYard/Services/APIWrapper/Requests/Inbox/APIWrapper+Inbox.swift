//
//  APIWrapper+Inbox.swift
//  SmartYard
//
//  Created by admin on 24/03/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
    /// Получить сообщения, заодно пометив их как прочитанные для сброса баджа уведомлений на сервере
    func inbox() -> Single<InboxResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = InboxRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.inbox(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    /// Пометить Push-уведомление как доставленное (чтобы сервер не отправлял их повторно)
    func delivered(messageId: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = DeliveredRequest(accessToken: accessToken, messageId: messageId)
        
        return provider.rx
            .request(.delivered(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    /// Получить количество непрочитанных уведомлений и сообщений чата (нужно для выставление баджа)
    func unreaded() -> Single<UnreadedResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = UnreadedRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.unreaded(request: request))
            .convertNoConnectionError()
            .mapAsDefaultResponse()
    }
    
    /// Пометить все сообщения чата как прочитанные. Нужно для сброса баджа чата на сервере
    func markChatAsReaded() -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ChatReadedRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.chatReaded(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
}
