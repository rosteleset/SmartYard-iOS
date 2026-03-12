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

final class IntercomTemporaryAccessView: PMNibLinkableView, HasDisposeBag {
    
    @IBOutlet fileprivate weak var refreshButton: UIButton!
    @IBOutlet fileprivate weak var openButton: SmartYardActionModeButton!
    @IBOutlet fileprivate weak var waitingGuestsQuestionMark: CircleIconControl!

    @IBOutlet private weak var codeLabel: UILabel!
    @IBOutlet private weak var containerView: FullRoundedView!
    
    @IBOutlet private var guestAccessToSuperviewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var codeTitleLabel: UILabel!
    @IBOutlet private weak var guestAccessTitleLabel: UILabel!
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
    
    private func configureUI() {
        titleLabel.text = L10n.Settings.AddressAccess.TemporaryAccess.title
        codeTitleLabel.text = L10n.Settings.AddressAccess.TemporaryAccess.codeTitle
        guestAccessTitleLabel.text = L10n.Settings.AddressAccess.TemporaryAccess.guestAccessTitle
        openButton.setTitle(L10n.Common.`open`, for: .normal)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
        openButton.mode = AccessService.shared.guestAccessModeOnOnly ? .open : .enable
        containerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
        waitingGuestsQuestionMark.style = .Others.question
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

extension IntercomTemporaryAccessView {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        containerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}
