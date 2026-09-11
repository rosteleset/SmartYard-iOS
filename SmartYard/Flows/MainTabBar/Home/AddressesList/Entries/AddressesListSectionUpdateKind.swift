//
//  AddressesListScrollingMode.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import UIKit

enum AddressesListSectionUpdateKind {
    
    case expand(sectionWithIdentity: AddressesListDataItemIdentity)
    case collapse(sectionWithIdentity: AddressesListDataItemIdentity)
    
    var associatedIdentity: AddressesListDataItemIdentity {
        switch self {
        case let .expand(identity): return identity
        case let .collapse(identity): return identity
        }
    }
    
}
