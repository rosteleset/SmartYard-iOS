//
//  IntercomTemporaryAccess.swift
//  SmartYard
//
//  Created by Mad Brains on 14.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxCocoa
import RxSwift

class IntercomTemporaryAccessView: PMNibLinkableView {
    
    @IBOutlet fileprivate weak var refreshButton: UIButton!
    @IBOutlet fileprivate weak var openButton: ObjectLockButton!
    
    @IBOutlet private weak var codeLabel: UILabel!
    @IBOutlet private weak var containerView: FullRoundedView!
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.borderWidth = 1
        containerView.borderColor = UIColor.SmartYard.grayBorder
    }
    
    func bind(with accessGranted: PublishSubject<Bool>, intercomCode: PublishSubject<String?>) {
        accessGranted
            .asDriver(onErrorJustReturn: false)
            .not()
            .drive(openButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        intercomCode
            .asDriver(onErrorJustReturn: "")
            .drive(codeLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}

extension Reactive where Base: IntercomTemporaryAccessView {
    
    var refreshButtonTapped: ControlEvent<Void> {
        return base.refreshButton.rx.tap
    }
    
    var openButtonTapped: ControlEvent<Void> {
        return base.openButton.rx.tap
    }
    
}
