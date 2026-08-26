//
//  ObjectLockButton.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit

final class SmartYardActionModeButton: UIButton {
    
    enum ActionMode {
        case open, enable, reset
    }

    enum VisualStyle {
        case standard, overImage
    }
    
    var mode: ActionMode = .open {
        didSet {
            prepareUI()
        }
    }

    var visualStyle: VisualStyle = .standard {
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
            switch mode {
            case .open:
                isEnabled = !isOn
            case .enable:
                isEnabled = true
                isSelected = isOn
            case .reset:
                isEnabled = !isOn
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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?
            .hasDifferentColorAppearance(comparedTo: traitCollection) == true
        else {
            return
        }

        prepareUI()
    }
    
    private func prepareUI() {
        layerCornerRadius = 8
        titleLabel?.font = UIFont.SourceSansPro.semibold(size: 14)
        titleLabel?.adjustsFontSizeToFitWidth = true

        switch mode {
        case .open:
            setTitle(L10n.Common.`open`, for: .normal)
            setTitle(L10n.Common.opened, for: .disabled)
            
            setTitleColor(.SmartYard.blue.darken(by: 0.1), for: .highlighted)

        case .enable:
            setTitle(L10n.Common.enable, for: .normal)
            setTitle(L10n.Common.disable, for: .selected)
            setTitle(L10n.Common.disable, for: [.highlighted, .selected])
            
            setTitleColor(.SmartYard.blue.darken(by: 0.1), for: .highlighted)
            setTitleColor(.SmartYard.secondBackgroundColor.darken(by: 0.1), for: [.highlighted, .selected])

        case .reset:
            setTitle(L10n.Common.reset, for: .normal)
            setTitle(L10n.Common.resetDone, for: .disabled)
            
            setTitleColor(.SmartYard.blue.darken(by: 0.1), for: .highlighted)
        }

        switch visualStyle {
        case .standard:
            setTitleColor(.SmartYard.blue, for: .normal)
            setTitleColor(.SmartYard.secondBackgroundColor, for: .selected)
            setTitleColor(.SmartYard.secondBackgroundColor, for: .disabled)

        case .overImage:
            setTitleColor(.SmartYard.mediaOverlayPrimary, for: .normal)
            setTitleColor(.SmartYard.mediaOverlayPrimary, for: .highlighted)
            setTitleColor(.SmartYard.secondBackgroundColor, for: .selected)
            setTitleColor(.SmartYard.secondBackgroundColor, for: .disabled)
        }

        updateAppearance()
    }
    
    private func updateAppearance() {
        switch visualStyle {
        case .standard:
            updateStandardAppearance()
        case .overImage:
            updateOverImageAppearance()
        }
    }

    private func updateStandardAppearance() {
        switch state {
        case .normal:
            backgroundColor = .SmartYard.secondBackgroundColor
            layerBorderWidth = 1
            setLayerBorderColor(.SmartYard.blue)
            
        case .highlighted:
            backgroundColor = .SmartYard.secondBackgroundColor.darken(by: 0.1)
            layerBorderWidth = 1
            setLayerBorderColor(UIColor.SmartYard.blue.darken(by: 0.1))
            
        case .disabled:
            backgroundColor = .SmartYard.darkGreen
            layerBorderWidth = 0
            setLayerBorderColor(.clear)
            
        case .selected:
            backgroundColor = .SmartYard.darkGreen
            layerBorderWidth = 0
            setLayerBorderColor(.clear)
            
        default:
            break
        }
    }

    private func updateOverImageAppearance() {
        switch state {
        case .normal:
            backgroundColor = .clear
            layerBorderWidth = 1
            setLayerBorderColor(.SmartYard.mediaOverlayPrimary)

        case .highlighted:
            backgroundColor = UIColor.SmartYard.mediaOverlaySecondary.withAlphaComponent(0.16)
            layerBorderWidth = 1
            setLayerBorderColor(.SmartYard.mediaOverlayPrimary)

        case .disabled:
            backgroundColor = .SmartYard.darkGreen
            layerBorderWidth = 0
            setLayerBorderColor(.clear)

        case .selected:
            backgroundColor = .SmartYard.darkGreen
            layerBorderWidth = 0
            setLayerBorderColor(.clear)

        default:
            break
        }
    }

    private func setLayerBorderColor(_ color: UIColor) {
        layer.borderColor = color.resolvedColor(with: traitCollection).cgColor
    }
    
}
