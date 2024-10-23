//
//  ServiceFromCourierView.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import PMNibLinkableView
import RxSwift
import RxCocoa

final class ServiceFromCourierView: PMNibLinkableView {
    
    @IBOutlet fileprivate weak var requestButton: BlueButton!
    
}

extension Reactive where Base: ServiceFromCourierView {
    
    var requestButtonTapped: ControlEvent<Void> {
        return base.requestButton.rx.tap
    }
    
}
