//
//  UnapprovedObjectCell.swift
//  SmartYard
//
//  Created by Mad Brains on 17.03.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UnapprovedObjectCell: CustomBorderCollectionViewCell {

    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var qrCodeButton: UIButton!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure(address: nil)
    }
    
    func configure(address: String?) {
        addressLabel.text = address
    }
    
    func bind(with outerSubject: PublishSubject<Void>) {
        qrCodeButton.rx.tap
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }

}
