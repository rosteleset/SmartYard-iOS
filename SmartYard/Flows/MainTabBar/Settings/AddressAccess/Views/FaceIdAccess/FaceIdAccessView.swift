//
//  FaceIdAccessView.swift
//  SmartYard
//
//  Created by Александр Васильев on 21.05.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import PMNibLinkableView
import RxCocoa
import RxSwift

class FaceIdAccessView: PMNibLinkableView {
    
    @IBOutlet private weak var containerView: FullRoundedView!
    @IBOutlet private weak var manageFacesView: UIView!
    @IBOutlet private weak var disabledView: UIView!
    
    @IBOutlet fileprivate weak var button: UIButton!
    
    private let disposeBag = DisposeBag()
    
    var isAvailable = false {
        didSet {
            disabledView.isHidden = isAvailable
            manageFacesView.isHidden = !isAvailable
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.borderWidth = 1
        containerView.borderColor = UIColor.SmartYard.grayBorder
        
    }
    
}

class SimpleButton: UIButton {
    
    override var isHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareUI()
    }
    
    private func prepareUI() {
        cornerRadius = 8
        titleLabel?.font = UIFont.SourceSansPro.semibold(size: 14)
        
        setTitleColor(UIColor.SmartYard.blue, for: .normal)
        
        setTitleColor(UIColor.SmartYard.blue.darken(by: 0.1), for: .highlighted)
        
        setTitleColor(.white, for: .disabled)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            backgroundColor = .white
            borderWidth = 1
            borderColor = UIColor.SmartYard.blue
            
        case .highlighted:
            backgroundColor = UIColor.white.darken(by: 0.1)
            borderWidth = 1
            borderColor = UIColor.SmartYard.blue.darken(by: 0.1)
            
        case .disabled:
            backgroundColor = UIColor.SmartYard.darkGreen
            borderWidth = 0
            borderColor = .clear
            
        default:
            break
        }
    }
    
}

extension Reactive where Base: FaceIdAccessView {
    
    var configureButtonTapped: ControlEvent<Void> {
        return base.button.rx.tap
    }
    
}
