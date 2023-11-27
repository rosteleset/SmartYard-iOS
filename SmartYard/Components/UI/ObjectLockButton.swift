//
//  ObjectLockButton.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

class ObjectLockButton: UIButton {
    
    var modeOnOnly = true {
        didSet {
            prepareUI()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    var isOn = false {
        didSet {
            if modeOnOnly {
                isEnabled = !isOn
                
            } else {
                isEnabled = true
                isSelected = isOn
            }
            updateAppearance()
        }
        
    }
    
    override init(frame: CGRect) {
        isOn = false
        super.init(frame: frame)
        prepareUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        isOn = false
        super.init(coder: aDecoder)
        prepareUI()
    }
    
    private func prepareUI() {
        layerCornerRadius = 8
        titleLabel?.font = UIFont.SourceSansPro.semibold(size: 14)
        
        if modeOnOnly {
            setTitleColor(UIColor.SmartYard.blue, for: .normal)
            setTitle(NSLocalizedString("Open", comment: ""), for: .normal)
        } else {
            setTitleColor(UIColor.SmartYard.blue, for: .normal)
            setTitle(NSLocalizedString("Enable", comment: ""), for: .normal)
        }
        
        setTitleColor(UIColor.SmartYard.blue.darken(by: 0.1), for: .highlighted)
        setTitle(NSLocalizedString("Open", comment: ""), for: .highlighted)
        
        setTitleColor(.white, for: .disabled)
        setTitle(NSLocalizedString("hasOpened", comment: ""), for: .disabled)
        
        setTitleColor(.white, for: .selected)
        setTitle(NSLocalizedString("Disable", comment: ""), for: .selected)
        
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        switch state {
        case .normal:
            backgroundColor = .white
            layerBorderWidth = 1
            layerBorderColor = UIColor.SmartYard.blue
            
        case .highlighted:
            backgroundColor = UIColor.white.darken(by: 0.1)
            layerBorderWidth = 1
            layerBorderColor = UIColor.SmartYard.blue.darken(by: 0.1)
            
        case .disabled:
            backgroundColor = UIColor.SmartYard.darkGreen
            layerBorderWidth = 0
            layerBorderColor = .clear
            
        case .selected:
            backgroundColor = UIColor.SmartYard.darkGreen
            layerBorderWidth = 0
            layerBorderColor = .clear
            
        default:
            break
        }
    }
    
}
