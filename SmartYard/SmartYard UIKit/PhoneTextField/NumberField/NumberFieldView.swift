//
//  NumberField.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class NumberFieldView: UIView {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var underlineView: UIView!
    
    private var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bind()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bind()
    }
    
    func setNewValue(value: Int?) {
        guard let newValue = value else {
            numberLabel.text = ""
            return
        }
        
        numberLabel.text = String(newValue)
    }

    private func bind() {
        numberLabel.rx.observe(String.self, "text")
            .subscribe(
                onNext: { [weak self] text in
                    self?.underlineView.isHidden = !(text?.isEmpty ?? true)
                }
            )
            .disposed(by: disposeBag)
    }
    
}
