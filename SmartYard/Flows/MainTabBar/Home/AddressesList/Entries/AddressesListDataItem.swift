//
//  AddressesDataItem.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

enum AddressesListDataItem: IdentifiableType, Equatable {
    
    case header(identity: AddressesListDataItemIdentity, address: String, isExpanded: Bool)
    case object(identity: AddressesListDataItemIdentity, type: DomophoneObjectType, name: String, isOpened: Bool)
    case cameras(identity: AddressesListDataItemIdentity, numberOfCameras: Int)
    case history(identity: AddressesListDataItemIdentity, numberOfEvents: Int)
    case unapprovedAddresses(identity: AddressesListDataItemIdentity, address: String)
    case addAddress
    case emptyState
    
}

extension AddressesListDataItem {
    
    var identity: AddressesListDataItemIdentity {
        switch self {
        case .header(let identity, _, _):
            return identity
        case .object(let identity, _, _, _):
            return identity
        case .cameras(let identity, _):
            return identity
        case .history(let identity, _):
            return identity
        case .unapprovedAddresses(let identity, _):
            return identity
        case .addAddress:
            return .addAddress
        case .emptyState:
            return .emptyState
        }
    }
    
}
