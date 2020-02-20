//
//  AddressesListObjectCell.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
        configure(objectType: .house, name: nil, isOpened: false)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    func configure(objectType: DomophoneObjectType, name: String?, isOpened: Bool) {
        nameLabel.text = name
        iconImageView.image = objectType.icon
        openButton.isSelected = isOpened
    }
    
    func bind(with outerSubject: PublishSubject<Void>) {
        openButton.rx
            .tap
            .subscribe(
                onNext: { _ in
                    outerSubject.onNext(())
                }
            )
            .disposed(by: disposeBag)
    }
    
}
