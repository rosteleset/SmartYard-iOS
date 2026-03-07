//
//  SettingsAddAddressCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SettingsAddAddressCell: UICollectionViewCell, HasDisposeBag {
    
    @IBOutlet private weak var addAddressButton: UIButton!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    private func configure() {
        addAddressButton.layerBorderWidth = 1
        addAddressButton.layerBorderColor = UIColor.SmartYard.blue
    }
    
    func bind(with outerSubject: PublishSubject<Void>) {
        addAddressButton.rx.tap
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }

}
