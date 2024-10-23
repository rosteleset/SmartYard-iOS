//
//  ContractCell.swift
//  SmartYard
//
//  Created by Mad Brains on 03.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class ContractCell: UICollectionViewCell {

    @IBOutlet private weak var contractNumLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var recommendedSumHintLabel: UILabel!
    @IBOutlet private weak var recommendedSumLabel: UILabel!
    @IBOutlet private weak var payButton: BlueButton!
    @IBOutlet private weak var openFullPersonalAccountButton: UIButton!
    
    @IBOutlet private weak var eyeButton: UIButton!
    @IBOutlet private weak var wifiButton: UIButton!
    @IBOutlet private weak var monitorButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var keyButton: UIButton!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contractNumLabel.text = nil
        balanceLabel.text = nil
        recommendedSumLabel.text = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func configure(with item: APIPaymentsListAccount) {
        contractNumLabel.text = item.contractName
        
        let formattedBalance = item.balance == 0 ? "0" : String(item.balance)
        balanceLabel.text = formattedBalance.replacingOccurrences(of: ".", with: ",") + " ₽"
        
        recommendedSumLabel.text = String(item.payAdvice ?? 0).replacingOccurrences(of: ".", with: ",") + " ₽"
        recommendedSumLabel.isHidden = item.payAdvice == nil
        recommendedSumHintLabel.isHidden = item.payAdvice == nil
        
        let enableColor = UIColor.SmartYard.blue
        let disableColor = UIColor.SmartYard.gray

        wifiButton.tintColor = (item.servicesAvailability[.internet] ?? false) ? enableColor : disableColor
        eyeButton.tintColor = (item.servicesAvailability[.cctv] ?? false) ? enableColor : disableColor
        monitorButton.tintColor = (item.servicesAvailability[.iptv] ?? false) ? enableColor : disableColor
        callButton.tintColor = (item.servicesAvailability[.phone] ?? false) ? enableColor : disableColor
        keyButton.tintColor = (item.servicesAvailability[.domophone] ?? false) ? enableColor : disableColor
        
        openFullPersonalAccountButton.isHidden = item.lcab == nil
    }
    
    func bind(with payOuterSubject: PublishSubject<Void>, openLkOuterSubject: PublishSubject<Void>) {
        payButton.rx.tap
            .bind(to: payOuterSubject)
            .disposed(by: disposeBag)
        
        openFullPersonalAccountButton.rx.tap
            .bind(to: openLkOuterSubject)
            .disposed(by: disposeBag)
    }
    
}
