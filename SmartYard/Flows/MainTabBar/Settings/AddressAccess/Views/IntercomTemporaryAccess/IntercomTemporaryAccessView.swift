//
//  IntercomTemporaryAccess.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxCocoa
import RxSwift

final class IntercomTemporaryAccessView: PMNibLinkableView {
    
    @IBOutlet fileprivate weak var refreshButton: UIButton!
    @IBOutlet fileprivate weak var openButton: ObjectLockButton!
    @IBOutlet fileprivate weak var waitingGuestsQuestionMark: UIButton!
    
    @IBOutlet private weak var codeLabel: UILabel!
    @IBOutlet private weak var containerView: FullRoundedView!
    
    @IBOutlet private var guestAccessToSuperviewTopConstraint: NSLayoutConstraint!
    
    private let disposeBag = DisposeBag()
    
    var isAccessGranted = false {
        didSet {
            openButton.isOn = isAccessGranted
        }
    }
    
    var intercomCode: String? {
        didSet {
            codeLabel.text = intercomCode
            guestAccessToSuperviewTopConstraint.isActive = intercomCode.isNilOrEmpty
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        openButton.modeOnOnly = AccessService.shared.guestAccessModeOnOnly
        containerView.layerBorderWidth = 1
        containerView.layerBorderColor = UIColor.SmartYard.grayBorder
    }
    
}

extension Reactive where Base: IntercomTemporaryAccessView {
    
    var refreshButtonTapped: ControlEvent<Void> {
        return base.refreshButton.rx.tap
    }
    
    var openButtonTapped: ControlEvent<Void> {
        return base.openButton.rx.tap
    }
    
    var waitingGuestsQuestionMarkTapped: ControlEvent<Void> {
        return base.waitingGuestsQuestionMark.rx.tap
    }

}
