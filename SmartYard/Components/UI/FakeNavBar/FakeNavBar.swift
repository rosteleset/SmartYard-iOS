//
//  FakeNavBar.swift
//  SmartYard
//
//  Created by admin on 11/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import PMNibLinkableView
import RxSwift
import RxCocoa

final class FakeNavBar: PMNibLinkableView {

    @IBOutlet fileprivate weak var backButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }

    private func configureUI() {
        backButton.setTitle(L10n.Common.back, for: .normal)
    }
    
    func configureBlueNavBar() {
        backButton.setTitleColor(UIColor.SmartYard.blue, for: .normal)
        backButton.tintColor = UIColor.SmartYard.blue
    }
    
    func configueDarkNavBar() {
        backButton.setTitleColor(UIColor.SmartYard.semiBlack, for: .normal)
        backButton.tintColor = UIColor.SmartYard.semiBlack
    }

    func configure(backgroundColor: UIColor?, contentColor: UIColor?) {
        if let backgroundColor {
            self.backgroundColor = backgroundColor
        }

        if let contentColor {
            backButton.setTitleColor(contentColor, for: .normal)
            backButton.tintColor = contentColor
        }
    }
    
    func setText(_ newText: String) {
        backButton.setTitle(newText, for: .normal)
    }
}

extension Reactive where Base: FakeNavBar {
    
    var backButtonTap: ControlEvent<Void> {
        return base.backButton.rx.tap
    }
    
}
