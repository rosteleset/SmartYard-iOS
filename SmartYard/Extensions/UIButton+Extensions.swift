//
//  UIButton+Extensions.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

extension UIButton {
    
    /// Выставляет иконки для .normal и .selected, а также темные иконки для .highlighted и [.selected, .highlighted]
    func configureSelectableButton(imageForNormal: UIImage?, imageForSelected: UIImage?) {
        setImage(imageForNormal, for: .normal)
        setImage(imageForNormal?.darkened(), for: [.normal, .highlighted])
        setImage(imageForSelected, for: .selected)
        setImage(imageForSelected?.darkened(), for: [.selected, .highlighted])
    }
    
}
