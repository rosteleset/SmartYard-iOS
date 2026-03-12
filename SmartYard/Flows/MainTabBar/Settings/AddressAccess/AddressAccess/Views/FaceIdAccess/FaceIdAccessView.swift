//
//  FaceIdAccessView.swift
//  SmartYard
//
//  Created by Александр Васильев on 21.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxCocoa
import RxSwift

final class FaceIdAccessView: PMNibLinkableView, HasDisposeBag {
    
    @IBOutlet private weak var containerView: FullRoundedView!
    @IBOutlet private weak var manageFacesView: UIView!
    @IBOutlet private weak var disabledView: UIView!
    
    @IBOutlet fileprivate weak var button: UIButton!
    @IBOutlet private weak var registeredFacesTitleLabel: UILabel!
    @IBOutlet private weak var disabledMessageLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var betaLabel: UILabel!
    var isAvailable = false {
        didSet {
            disabledView.isHidden = isAvailable
            manageFacesView.isHidden = !isAvailable
        }
    }
    
    private func configureUI() {
        registeredFacesTitleLabel.text = L10n.Settings.AddressAccess.FaceID.registeredFaces
        button.setTitle(L10n.Settings.AddressAccess.FaceID.setupButton, for: .normal)
        disabledMessageLabel.text = L10n.Settings.AddressAccess.FaceID.disabledMessage
        titleLabel.text = L10n.Settings.AddressAccess.FaceID.title
        betaLabel.text = L10n.Settings.AddressAccess.FaceID.beta
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
        containerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}

extension Reactive where Base: FaceIdAccessView {
    
    var configureButtonTapped: ControlEvent<Void> {
        return base.button.rx.tap
    }
    
}

extension FaceIdAccessView {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        containerView.addBorder(dynamicColor: UIColor.SmartYard.grayBorder)
    }
    
}
