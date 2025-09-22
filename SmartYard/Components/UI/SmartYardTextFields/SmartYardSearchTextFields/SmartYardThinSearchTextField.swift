//
//  SmartYardThinSearchTextField.swift
//  SmartYard
//
//  Created by Александр Попов on 20.07.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import UIKit

final class SmartYardThinSearchTextField: SmartYardLicensePlateTextField {
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 8, left: 32, bottom: 8, right: 8))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 8, left: 32, bottom: 8, right: 8))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    private func configureUI() {
        placeholder = NSLocalizedString("Search", comment: "")
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.SmartYard.gray.withAlphaComponent(0.3).cgColor
        backgroundColor = .clear
        borderStyle = .none
        font = UIFont.SourceSansPro.regular(size: 16)
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 32))
        let imageView = UIImageView(image: UIImage(named: "SearchIcon"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.SmartYard.gray
        imageView.frame = CGRect(x: 8, y: 8, width: 16, height: 16)
        leftView.addSubview(imageView)
        
        self.leftView = leftView
        leftViewMode = .always
    }

}
