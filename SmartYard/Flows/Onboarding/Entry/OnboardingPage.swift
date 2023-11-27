//
//  OnboardingPages.swift
//  SmartYard
//
//  Created by Mad Brains on 21.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

enum OnboardingPage: Int, CaseIterable {
    
    case cctv = 0
    case fullControl
    case smartYard
    
    var image: UIImage? {
        switch self {
        case .cctv: return UIImage(named: "FirstOnboardingPageIcon")
        case .fullControl: return UIImage(named: "SecondOnboardingPageIcon")
        case .smartYard: return UIImage(named: "ThirdOnboardingPageIcon")
        }
    }
    
    var titleText: String {
        switch self {
        case .cctv: return NSLocalizedString("Video surveillance", comment: "")
        case .fullControl: return NSLocalizedString("Everything's under control", comment: "")
        case .smartYard: return NSLocalizedString("Smart yard", comment: "")
        }
    }
    
    var subTitleText: String {
        switch self {
        case .cctv: return NSLocalizedString("Be aware of everything that happens near the house", comment: "")
        case .fullControl: return NSLocalizedString("Manage services and pay for them via the app", comment: "")
        case .smartYard: return NSLocalizedString("Control your intercom, gate or barrier from your smartphone", comment: "")
        }
    }
    
}
