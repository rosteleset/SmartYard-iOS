//
//  WdgObjectCell.swift
//  LanTa
//
//  Created by Mad Brains on 08.04.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import SmartYardSharedDataFramework
import RxSwift
import RxCocoa

class WdgObjectCell: UITableViewCell, HasDisposeBag {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var objectNameLabel: UILabel!
    @IBOutlet private weak var objectAddressLabel: UILabel!
    @IBOutlet private weak var lockButton: UIButton!
 
    static let reuseIdentifier = "WdgObjectCellId"
    static let defaultHeight: CGFloat = 72
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        resetDisposeBag()
    }
    
    func configure(with object: SmartYardSharedObject, isOpened: Bool) {
        iconImageView.image = UIImage(named: object.logoImageName)
        objectNameLabel.text = object.objectName
        objectAddressLabel.text = object.objectAddress
        objectAddressLabel.textColor = UIColor(named: "CustomGreyColor")
        iconImageView.tintColor = UIColor(named: "CustomGreyColor")
        
        lockButton.isUserInteractionEnabled = !isOpened
        
        let lockButtonImage = UIImage(named: isOpened ? "OpenStateIcon" : "CloseStateIcon")
        lockButton.setImage(lockButtonImage, for: .normal)
    }
    
    func bind(with outerSubject: PublishSubject<Void>) {
        lockButton.rx.tap
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }
    
}
