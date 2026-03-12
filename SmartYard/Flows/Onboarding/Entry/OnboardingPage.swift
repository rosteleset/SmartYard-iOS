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
        case .cctv: return L10n.Services.Catalog.videoSurveillance
        case .fullControl: return L10n.Onboarding.Control.title
        case .smartYard: return L10n.Onboarding.SmartYard.title
        }
    }
    
    var subTitleText: String {
        switch self {
        case .cctv: return L10n.Onboarding.Awareness.title
        case .fullControl: return L10n.Onboarding.Services.subtitle
        case .smartYard: return L10n.Onboarding.Intercom.subtitle
        }
    }
    
}
