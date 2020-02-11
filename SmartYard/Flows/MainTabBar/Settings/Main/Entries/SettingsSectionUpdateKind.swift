//
//  SettingsScrollingMode.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

enum SettingsSectionUpdateKind {
    
    case expand(sectionWithIdentity: SettingsDataItemIdentity)
    case collapse(sectionWithIdentity: SettingsDataItemIdentity)
    
    var associatedIdentity: SettingsDataItemIdentity {
        switch self {
        case let .expand(identity): return identity
        case let .collapse(identity): return identity
        }
    }
    
}
