//
//  TopRoundedView.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit

class TopRoundedView24: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners([.topLeft, .topRight], radius: 24.0)
    }
}

class TopRoundedView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners([.topLeft, .topRight], radius: 12.0)
    }
}
