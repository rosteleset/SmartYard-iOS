//
//  DoorsDataItem.swift
//  SmartYard
//
//  Created by devcentra on 24.04.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import RxDataSources

enum DoorsDataItem: IdentifiableType, Equatable {
    
    case object(identity: DoorsDataItemIdentity, type: DomophoneObjectType, name: String, isOpened: Bool)
    case emptyState
    
}

extension DoorsDataItem {
    
    var identity: DoorsDataItemIdentity {
        switch self {
        case .object(let identity, _, _, _):
            return identity
        case .emptyState:
            return .emptyState
        }
    }
    
}
