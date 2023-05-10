//
//  ChatwootGetMessagesRequest.swift
//  SmartYard
//
//  Created by devcentra on 30.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

struct ChatwootGetMessagesRequest {
    
    let accessToken: String
    let chat: String
    let before: Int?
    let forceRefresh: Bool

}

extension ChatwootGetMessagesRequest {
    
    var requestParameters: [String: Any] {
        var params: [String: Any] = [
            "chat": chat
        ]
        
        if let before = before {
            params["before"] = before
        }

        return params
    }
    
}
