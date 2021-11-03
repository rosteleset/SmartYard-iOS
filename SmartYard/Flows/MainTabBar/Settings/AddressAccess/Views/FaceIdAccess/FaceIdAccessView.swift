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
        
        containerView.layerBorderWidth = 1
        containerView.layerBorderColor = UIColor.SmartYard.grayBorder
        
    }
    
}

extension Reactive where Base: FaceIdAccessView {
    
    var configureButtonTapped: ControlEvent<Void> {
        return base.button.rx.tap
    }
    
}
