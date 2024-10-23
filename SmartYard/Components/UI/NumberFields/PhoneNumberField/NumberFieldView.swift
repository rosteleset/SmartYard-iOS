//
//  NumberField.swift
//  SmartYard
//
//  Created by Mad Brains on 05.02.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import PMNibLinkableView

final class NumberFieldView: PMNibLinkableView {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var numberLabel: UILabel!
    @IBOutlet private weak var underlineView: UIView!
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bind()
    }
    
    func fetchValue() -> String? {
        return numberLabel.text
    }
    
    func clear() {
        numberLabel.text = nil
    }
    
    func setNewValue(value: String?) {
        numberLabel.text = value
    }
    
    private func bind() {
        numberLabel.rx.observe(String.self, "text")
            .subscribe(
                onNext: { [weak self] text in
                    self?.underlineView.isHidden = !text.isNilOrEmpty
                }
            )
            .disposed(by: disposeBag)
    }
    
}
