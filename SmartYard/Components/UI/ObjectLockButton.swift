//
//  ObjectLockButton.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class ObjectLockButton: UIButton {
    
    override var isHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override var isSelected: Bool {
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
        
        setTitleColor(UIColor(hex: 0x298BFF), for: .normal)
        setTitle("Открыть", for: .normal)
        
        setTitleColor(UIColor(hex: 0x298BFF)?.darken(by: 0.1), for: .highlighted)
        setTitle("Открыть", for: .highlighted)
        
        setTitleColor(.white, for: .selected)
        setTitle("Открыто", for: .selected)
        
        setTitleColor(UIColor.white.darken(by: 0.1), for: [.selected, .highlighted])
        setTitle("Открыто", for: [.selected, .highlighted])
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            backgroundColor = .white
            borderWidth = 1
            borderColor = UIColor(hex: 0x298BFF)
            
        case .selected:
            backgroundColor = UIColor(hex: 0x1FBC62)
            borderWidth = 0
            borderColor = .clear
            
        case .highlighted:
            backgroundColor = UIColor.white.darken(by: 0.1)
            borderWidth = 1
            borderColor = UIColor(hex: 0x298BFF)?.darken(by: 0.1)
            
        case [.selected, .highlighted]:
            backgroundColor = UIColor(hex: 0x1FBC62)?.darken(by: 0.1)
            borderWidth = 0
            borderColor = .clear
            
        default:
            break
        }
    }
    
}
