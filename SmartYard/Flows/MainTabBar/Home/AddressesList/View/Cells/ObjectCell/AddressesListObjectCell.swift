//
//  AddressesListObjectCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddressesListObjectCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var openButton: ObjectLockButton!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure(objectType: .entrance, name: nil, isOpened: false)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    func configure(objectType: DomophoneObjectType, name: String?, isOpened: Bool) {
        nameLabel.text = name
        iconImageView.image = objectType.icon
        openButton.isEnabled = !isOpened
    }
    
    func bind(with outerSubject: PublishSubject<Void>) {
        openButton.rx.tap
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }
    
}
