//
//  SmartYardDropDownTextField.swift
//  SmartYard
//
//  Created by Александр Васильев on 26.02.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class SmartYardDropDownTextField: SmartYardTextField {
    
    private let dropDownImage: UIImageView = {
        let image = UIImageView(image: UIImage(named: "DownArrowIcon"))
        
        image.frame = CGRect(x: 0, y: 0, width: 13, height: 8)
        
        return image
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    override init() {
        super.init()
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.maxX - 20 - 13,
            y: (bounds.height - 8) / 2,
            width: 13,
            height: 8
        )
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 1 + 20 + 13))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 1 + 20 + 13))
    }
    
    private func configureUI() {
        dropDownImage.tintColor = UIColor(hex: 0x6D7A8A)?.withAlphaComponent(0.5)
        rightViewMode = .always
        
        rightView = dropDownImage
    }

}
