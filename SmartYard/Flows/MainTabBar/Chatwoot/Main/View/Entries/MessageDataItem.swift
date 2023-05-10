//
//  MessageDataItem.swift
//  SmartYard
//
//  Created by devcentra on 04.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import MessageKit

struct MessageDataItem: MessageType {
    
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    public init(
        sender: SenderType,
        messageId: String,
        sentDate: Date,
        kind: MessageKind
    ) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = sentDate
        self.kind = kind
    }

}
