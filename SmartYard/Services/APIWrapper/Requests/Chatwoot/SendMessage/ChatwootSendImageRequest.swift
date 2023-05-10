//
//  ChatwootSendImageRequest.swift
//  SmartYard
//
//  Created by devcentra on 12.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

struct ChatwootSendImageRequest {
    
    let accessToken: String
    let chat: String
    let messageType: String
    let image: String
    
}

extension ChatwootSendImageRequest {
    
    var requestParameters: [String: Any] {
        return [
            "chat": chat,
            "message_type": messageType,
            "images": [image]
        ]
    }
    
}
