//
//  ServiceFromCourierView.swift
//  SmartYard
//
//  Created by Mad Brains on 11.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import PMNibLinkableView
import RxSwift
import RxCocoa

class ServiceFromCourierView: PMNibLinkableView {
    // swiftlint:disable:next strict_fileprivate
    @IBOutlet fileprivate weak var requestButton: BlueButton!
    
}

extension Reactive where Base: ServiceFromCourierView {
    
    var requestButtonTapped: ControlEvent<Void> {
        return base.requestButton.rx.tap
    }
    
}
