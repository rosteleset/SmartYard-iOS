//
//  DoorsDataItemIdentity.swift
//  SmartYard
//
//  Created by devcentra on 24.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

enum DoorsDataItemIdentity: Hashable {
    
    case object(domophoneId: String, doorId: Int)
    case emptyState
    
}
