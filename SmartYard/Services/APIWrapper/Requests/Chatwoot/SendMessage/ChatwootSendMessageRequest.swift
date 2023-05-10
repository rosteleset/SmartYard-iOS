//
//  ChatwootSendMessageRequest.swift
//  SmartYard
//
//  Created by devcentra on 30.03.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

struct ChatwootSendMessageRequest {
    
    let accessToken: String
    let chat: String
    let message: String
    
}

extension ChatwootSendMessageRequest {
    
    var requestParameters: [String: Any] {
        return [
            "chat": chat,
            "message": message
        ]
    }
    
}
