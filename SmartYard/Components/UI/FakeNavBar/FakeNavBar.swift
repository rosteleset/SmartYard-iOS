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

    @IBOutlet fileprivate weak var backButton: UIButton!
    
    func configureBlueNavBar() {
        backButton.setTitleColor(UIColor.SmartYard.blue, for: .normal)
        backButton.tintColor = UIColor.SmartYard.blue
    }
    
}

extension Reactive where Base: FakeNavBar {
    
    var backButtonTap: ControlEvent<Void> {
        return base.backButton.rx.tap
    }
    
}
