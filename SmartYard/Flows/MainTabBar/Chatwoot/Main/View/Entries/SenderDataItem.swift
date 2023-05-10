//
//  SenderDataItem.swift
//  SmartYard
//
//  Created by devcentra on 04.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import MessageKit

struct SenderDataItem: SenderType {
    var senderId: String
    var displayName: String
}

extension SenderDataItem {
    
    init(id: Int, name: String) {
        self.senderId = String(id)
        self.displayName = name
    }
    
}
