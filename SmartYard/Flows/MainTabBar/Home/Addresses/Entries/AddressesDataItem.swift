//
//  AddressesDataItem.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxDataSources

enum AddressesDataItem: IdentifiableType, Equatable {
    
    case header(identity: AddressesDataItemIdentity, address: String, isExpanded: Bool)
    
}

extension AddressesDataItem {
    
    var identity: AddressesDataItemIdentity {
        switch self {
        case .header(let identity, _, _):
            return identity
        }
    }
    
}
