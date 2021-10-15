//
//  OnboardingBaseView.swift
//  SmartYard
//
//  Created by Mad Brains on 22.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import PMNibLinkableView

class OnboardingBaseView: PMNibLinkableView {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    
    func configure(with pageType: OnboardingPage) {
        imageView.image = pageType.image
        titleLabel.text = pageType.titleText
        subTitleLabel.text = pageType.subTitleText
    }
    
}
