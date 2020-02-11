//
//  FakeNavBar.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import PMNibLinkableView
import RxSwift
import RxCocoa

class FakeNavBar: PMNibLinkableView {

    // swiftlint:disable:next strict_fileprivate
    @IBOutlet fileprivate weak var backButton: UIButton!
    
}

extension Reactive where Base: FakeNavBar {
    
    var backButtonTap: ControlEvent<Void> {
        return base.backButton.rx.tap
    }
    
}
