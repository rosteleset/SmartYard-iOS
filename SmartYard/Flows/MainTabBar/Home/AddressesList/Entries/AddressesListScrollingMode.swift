//
//  AddressesListScrollingMode.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

enum AddressesListScrollingMode {
    
    case expand(sectionWithIdentity: AddressesListDataItemIdentity)
    case collapse(sectionWithIdentity: AddressesListDataItemIdentity)
    
    var associatedIdentity: AddressesListDataItemIdentity {
        switch self {
        case let .expand(identity): return identity
        case let .collapse(identity): return identity
        }
    }
    
    var scrollingPosition: UICollectionView.ScrollPosition {
        switch self {
        case .expand: return .top
        case .collapse: return []
        }
    }
    
}
