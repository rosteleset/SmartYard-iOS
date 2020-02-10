//
//  SettingsControlPanelCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import UIKit

class SettingsControlPanelCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var wifiButton: UIButton!
    @IBOutlet private weak var monitorButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var keyButton: UIButton!
    @IBOutlet private weak var eyeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureButtons()
    }
    
    func configure(
        isWiFiEnabled: Bool,
        isMonitorEnabled: Bool,
        isCallEnabled: Bool,
        isKeyEnabled: Bool,
        isEyeEnabled: Bool
    ) {
        wifiButton.isSelected = isWiFiEnabled
        monitorButton.isSelected = isMonitorEnabled
        callButton.isSelected = isCallEnabled
        keyButton.isSelected = isKeyEnabled
        eyeButton.isSelected = isEyeEnabled
    }
    
    private func configureButtons() {
        wifiButton.configureSelectableButton(
            imageForNormal: UIImage(named: "SettingsWiFiUnselectedIcon"),
            imageForSelected: UIImage(named: "SettingsWiFiSelectedIcon")
        )
        
        monitorButton.configureSelectableButton(
            imageForNormal: UIImage(named: "SettingsMonitorUnselectedIcon"),
            imageForSelected: UIImage(named: "SettingsMonitorSelectedIcon")
        )
        
        callButton.configureSelectableButton(
            imageForNormal: UIImage(named: "SettingsCallUnselectedIcon"),
            imageForSelected: UIImage(named: "SettingsCallSelectedIcon")
        )
        
        keyButton.configureSelectableButton(
            imageForNormal: UIImage(named: "SettingsKeyUnselectedIcon"),
            imageForSelected: UIImage(named: "SettingsKeySelectedIcon")
        )
        
        eyeButton.configureSelectableButton(
            imageForNormal: UIImage(named: "SettingsEyeUnselectedIcon"),
            imageForSelected: UIImage(named: "SettingsEyeSelectedIcon")
        )
    }

}
