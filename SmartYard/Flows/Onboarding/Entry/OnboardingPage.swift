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
        case .cctv: return "Видеонаблюдение"
        case .fullControl: return "Всё под контролем"
        case .smartYard: return "Умный двор"
        }
    }
    
    var subTitleText: String {
        switch self {
        case .cctv: return "Будь в курсе всего, что происходит возле дома"
        case .fullControl: return "Управляй услугами и оплачивай их через приложение"
        case .smartYard: return "Управляй домофоном, воротами или шлагбаумом со смартфона"
        }
    }
    
}
