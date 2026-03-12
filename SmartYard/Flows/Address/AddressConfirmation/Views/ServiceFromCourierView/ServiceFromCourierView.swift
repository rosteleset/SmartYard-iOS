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
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var envelopeHintLabel: UILabel!
    @IBOutlet private weak var qrCodeTitleLabel: UILabel!
    @IBOutlet private weak var qrCodeHintLabel: UILabel!
    @IBOutlet private weak var useLabel: UILabel!
    @IBOutlet private weak var activationHintLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    private func configureUI() {
        titleLabel.text = L10n.Address.Confirmation.Courier.leaveARequest
        envelopeHintLabel.text = L10n.Address.Confirmation.Courier.envelopeHint
        qrCodeTitleLabel.text = L10n.Address.Confirmation.Courier.scanTheQrCode
        qrCodeHintLabel.text = L10n.Address.Confirmation.Courier.qrCodeHint
        useLabel.text = L10n.Address.Confirmation.Courier.use
        activationHintLabel.text = L10n.Address.Confirmation.Courier.activationHint
        requestButton.setTitle(L10n.Address.Confirmation.Courier.requestButton, for: .normal)
    }
}

extension Reactive where Base: ServiceFromCourierView {
    
    var requestButtonTapped: ControlEvent<Void> {
        return base.requestButton.rx.tap
    }
    
}
