//
//  ChatwootGetChatListRequest.swift
//  SmartYard
//
//  Created by devcentra on 03.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

struct ChatwootGetChatListRequest {
    
    let accessToken: String
    let forceRefresh: Bool

}

extension ChatwootGetChatListRequest {
    
    var requestParameters: [String: Any] {
        return [:]
    }
    
}
