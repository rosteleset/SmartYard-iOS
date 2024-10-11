//
//  FakeNavBar.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
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
    
    func configueDarkNavBar() {
        backButton.setTitleColor(UIColor.SmartYard.semiBlack, for: .normal)
        backButton.tintColor = UIColor.SmartYard.semiBlack
    }
    
    func configueBlueNavBar() {
        backButton.setTitleForAllStates(" ")
        backButton.tintColor = UIColor.SmartYard.blue
    }
    
    func setText(_ newText: String) {
        backButton.setTitle(newText, for: .normal)
    }
    
    func addWebViewAction(_ target: BaseViewController, action: Selector) {
        backButton.addTarget(target, action: action, for: .touchUpInside)
    }
}

extension Reactive where Base: FakeNavBar {
    
    var backButtonTap: ControlEvent<Void> {
        return base.backButton.rx.tap
    }
    
}
