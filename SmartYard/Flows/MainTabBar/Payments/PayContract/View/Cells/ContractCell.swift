//
//  ContractCell.swift
//  SmartYard
//
//  Created by Mad Brains on 03.04.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ContractCell: UICollectionViewCell {

    @IBOutlet private weak var contractNumLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var recommendedSumLabel: UILabel!
    @IBOutlet private weak var payButton: BlueButton!
    @IBOutlet private weak var openFullPersonalAccountButton: UIButton!
    
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
    
    func configure(with item: PaymentAddressItem) {
        contractNumLabel.text = item.contractNum
        balanceLabel.text = item.balance
        recommendedSumLabel.text = item.recommendedSum
    }
    
    func bind(with outerSubject: PublishSubject<Void>) {
        payButton.rx.tap
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }
    
}
