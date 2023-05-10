//
//  APIWrapper+Chatwoot.swift
//  SmartYard
//
//  Created by devcentra on 30.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension APIWrapper {
    
    /// Получить сообщения чата
    func chatwootinbox(
        chat: String,
        before: Int? = nil,
        forceRefresh: Bool = false) -> Single<ChatwootGetMessagesResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forseUpdateChatwootChat || forceRefresh
        forseUpdateChatwootChat = false

        let request = ChatwootGetMessagesRequest(
            accessToken: accessToken,
            chat: chat,
            before: before,
            forceRefresh: forceRefresh
        )
        
        return provider.rx
            .request(.chatwootinbox(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }

    /// Отправить сообщение в чат
    func chatwootsend(chat: String, message: String) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let request = ChatwootSendMessageRequest(accessToken: accessToken, chat: chat, message: message)
        
        return provider.rx
            .request(.chatwootsend(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }
    
    func chatwootsendimage(chat: String, image: UIImage) -> Single<Void?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        guard let imgData = image.jpegBase64String(compressionQuality: 1) else {
            return .error(NSError.APIWrapperError.noImageBase64Converted)
        }
        
        let request = ChatwootSendImageRequest(
            accessToken: accessToken,
            chat: chat,
            messageType: "image",
            image: imgData
        )
        
        return provider.rx
            .request(.chatwootsendimage(request: request))
            .convertNoConnectionError()
            .mapAsVoidResponse()
            .mapToOptional()
    }

    /// Получить список чатов
    func chatwootlist(forceRefresh: Bool = false) -> Single<ChatwootGetChatListResponseData?> {
        guard isReachable else {
            return .error(NSError.APIWrapperError.noConnectionError)
        }
        
        guard let accessToken = accessService.accessToken else {
            return .error(NSError.APIWrapperError.accessTokenMissingError)
        }
        
        let forceRefresh = forseUpdateChatwootList || forceRefresh
        forseUpdateChatwootList = false

        let request = ChatwootGetChatListRequest(accessToken: accessToken, forceRefresh: forceRefresh)
        
        return provider.rx
            .request(.chatwootlist(request: request))
            .convertNoConnectionError()
            .mapAsEmptyDataInitializableResponse()
            .mapToOptional()
    }

}
