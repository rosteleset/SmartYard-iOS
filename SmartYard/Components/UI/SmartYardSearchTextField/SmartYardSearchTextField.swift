//
//  SmartYardSearchTextField.swift
//  SmartYard
//
//  Created by Mad Brains on 05.03.2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import Foundation
import SearchTextField

final class SmartYardSearchTextField: SearchTextField {
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureUI()
    }
    
    init() {
        super.init(frame: .zero)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setPlaceholder(string: String, isRequiredField: Bool = false, isSemiBold: Bool = false) {
        let font = isSemiBold ? UIFont.SourceSansPro.semibold(size: 18)
            : UIFont.SourceSansPro.regular(size: 18)
        
        let attrString = NSAttributedString(
            string: string,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.SmartYard.gray.withAlphaComponent(0.4) as Any
            ]
        )
        
        guard isRequiredField else {
            attributedPlaceholder = attrString
            return
        }
        
        let requirementString = NSAttributedString(
            string: "*",
            attributes: [
                .font: font,
                .foregroundColor: UIColor.SmartYard.gray.withAlphaComponent(0.4) as Any,
                .baselineOffset: 3
            ]
        )
        
        attributedPlaceholder = attrString + requirementString
    }
    
    private func configureUI() {
        tintColor = UIColor.SmartYard.semiBlack
    }
    
}
