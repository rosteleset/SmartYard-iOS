//
//  SmartYardCheckBoxView.swift
//  SmartYard
//
//  Created by Mad Brains on 12.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit
import PMNibLinkableView
import RxCocoa
import RxSwift

class SmartYardCheckBoxView: PMNibLinkableView {
    
    @IBOutlet private weak var borderImageView: UIImageView!
    @IBOutlet private weak var checkImageView: UIImageView!
    @IBOutlet private weak var checkButton: UIButton!
    
    private var currentState: ServiceState = .uncheckedActive {
        didSet {
            borderImageView.tintColor = currentState.borderTintColor
            checkImageView.tintColor = currentState.checkTintColor
        }
    }
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bind()
    }
    
    func setState(state: ServiceState) {
        currentState = state
    }
    
    private func bind() {
        checkButton.rx.tap.asDriver()
            .drive(
                onNext: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    
                    switch self.currentState {
                    case .checkedActive: self.setState(state: .uncheckedActive)
                    case .checkedInactive: break
                    case .uncheckedActive: self.setState(state: .checkedActive)
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
}
