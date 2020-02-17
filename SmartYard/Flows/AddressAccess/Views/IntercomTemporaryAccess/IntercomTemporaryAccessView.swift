//
//  IntercomTemporaryAccess.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxCocoa
import RxSwift

class IntercomTemporaryAccessView: PMNibLinkableView {
    
    // swiftlint:disable:next strict_fileprivate
    @IBOutlet fileprivate weak var refreshButton: UIButton!
    // swiftlint:disable:next strict_fileprivate
    @IBOutlet fileprivate weak var openButton: WhiteButtonWithBorder!
    
    @IBOutlet private weak var codeLabel: UILabel!
    
    func configure(code: String) {
        codeLabel.text = code
    }
    
}

extension Reactive where Base: IntercomTemporaryAccessView {
    
    var refreshButtonTapped: ControlEvent<Void> {
        return base.refreshButton.rx.tap
    }
    
    var openButtonTapped: ControlEvent<Void> {
        return base.openButton.rx.tap
    }
    
}
