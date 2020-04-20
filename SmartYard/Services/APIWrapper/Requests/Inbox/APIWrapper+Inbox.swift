//
//  APIWrapper+Inbox.swift
//  SmartYard
//
//  Created by admin on 24/03/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
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
            .catchNoConnectionError()
            .mapAsDefaultResponse()
    }
    
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
            .catchNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
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
            .catchNoConnectionError()
            .mapAsDefaultResponse()
    }
    
}
