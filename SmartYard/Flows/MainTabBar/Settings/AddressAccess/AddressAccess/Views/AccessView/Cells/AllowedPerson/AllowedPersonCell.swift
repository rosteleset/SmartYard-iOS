//
//  AllowedPersonCell.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class AllowedPersonCell: UITableViewCell, HasDisposeBag {

    @IBOutlet private weak var userLogoImageView: RoundedImageView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var smsButton: UIButton!
    
    @IBOutlet private var nameTrailingToSmsButtonConstraint: NSLayoutConstraint!
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetDisposeBag()
    }
    
    func configure(with person: AllowedPerson) {
        userNameLabel.text = person.displayedName ?? person.displayedNumber
        userLogoImageView.image = person.logoImage ?? UIImage(named: "DefaultUserIcon")
    }
    
    func configureSMSButton(isAvailable: Bool, subjectProxyIfAvailable: PublishSubject<Void>?) {
        smsButton.isHidden = !isAvailable
        nameTrailingToSmsButtonConstraint.isActive = isAvailable
        
        guard let outerSubject = subjectProxyIfAvailable else {
            return
        }
        
        smsButton.rx.tap
            .subscribe(
                onNext: { _ in
                    outerSubject.onNext(())
                }
            )
            .disposed(by: disposeBag)
    }
    
}

