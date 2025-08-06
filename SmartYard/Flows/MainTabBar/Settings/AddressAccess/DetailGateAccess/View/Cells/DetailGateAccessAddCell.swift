//
//  SettingsAddAddressCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

final class DetailGateAccessAddCell: UICollectionViewCell {
    
    // MARK: - Reuse Identifier
    
    static let reuseIdentifier = "DetailGateAccessAddCell"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var addAddressButton: UIButton!
    
    // MARK: - Properties

    private var disposeBag = DisposeBag()
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addAddressButton.layerBorderWidth = 1
        addAddressButton.layerBorderColor = UIColor.SmartYard.blue
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    // MARK: - Configuration
    
    func configure(with type: GateAccessShortcutType) {
        addAddressButton.setTitleForAllStates(type.title)
    }
    
    // MARK: - Binding
    
    func bind(with outerSubject: PublishRelay<Void>) {
        addAddressButton.rx.tap
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }

}
