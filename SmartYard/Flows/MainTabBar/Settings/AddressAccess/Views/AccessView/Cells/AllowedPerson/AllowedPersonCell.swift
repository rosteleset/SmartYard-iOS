//
//  AllowedPersonCell.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AllowedPersonCell: UITableViewCell {

    @IBOutlet private weak var userLogoImageView: RoundedImageView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var smsButton: UIButton!
    
    var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    func configure(with person: AllowedPerson) {
        userNameLabel.text = person.displayedName ?? person.formattedNumber
        userLogoImageView.image = person.logoImage ?? UIImage(named: "DefaultUserIcon")
    }
    
    func bind(with outerSubject: PublishSubject<Void>) {
        smsButton.rx.tap
            .subscribe(
                onNext: { _ in
                    outerSubject.onNext(())
                }
            )
            .disposed(by: disposeBag)
    }
    
}

