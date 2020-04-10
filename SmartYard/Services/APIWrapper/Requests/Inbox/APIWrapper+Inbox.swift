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
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = InboxRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.inbox(request: request))
            .mapAsDefaultResponse()
    }
    
    func delivered(messageId: String) -> Single<Void?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = DeliveredRequest(accessToken: accessToken, messageId: messageId)
        
        return provider.rx
            .request(.delivered(request: request))
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func unreaded() -> Single<UnreadedResponseData?> {
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = UnreadedRequest(accessToken: accessToken)
        
        return provider.rx
            .request(.unreaded(request: request))
            .mapAsDefaultResponse()
    }
    
}
