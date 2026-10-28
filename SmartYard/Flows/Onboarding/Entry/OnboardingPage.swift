//
//  OnboardingPages.swift
//  SmartYard
//
//  Created by Mad Brains on 21.04.2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import Foundation

enum OnboardingPage: Int, CaseIterable {
    
    case cctv = 0
    case fullControl
    case smartYard
    
    var imageName: String {
        switch self {
        case .cctv: return "FirstOnboardingPageIcon"
        case .fullControl: return "SecondOnboardingPageIcon"
        case .smartYard: return "ThirdOnboardingPageIcon"
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
