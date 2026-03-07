//
//  UnapprovedObjectCell.swift
//  SmartYard
//
//  Created by Mad Brains on 17.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class UnapprovedObjectCell: CustomBorderCollectionViewCell, HasDisposeBag {

    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var qrCodeButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configure(address: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetDisposeBag()
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
