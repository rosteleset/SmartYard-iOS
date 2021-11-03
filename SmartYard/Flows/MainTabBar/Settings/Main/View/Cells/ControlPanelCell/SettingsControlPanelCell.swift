//
//  SettingsControlPanelCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SettingsControlPanelCell: CustomBorderCollectionViewCell {
    
    @IBOutlet private weak var wifiButton: UIButton!
    @IBOutlet private weak var monitorButton: UIButton!
    @IBOutlet private weak var callButton: UIButton!
    @IBOutlet private weak var keyButton: UIButton!
    @IBOutlet private weak var eyeButton: UIButton!
    
    var disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureButtons()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func bind(with outerSubject: PublishSubject<SettingsServiceType>) {
        let internet = wifiButton.rx.tap
            .map { _ -> SettingsServiceType in .internet }
        
        let tv = monitorButton.rx.tap
            .map { _ -> SettingsServiceType in .iptv }
        
        let phone = callButton.rx.tap
            .map { _ -> SettingsServiceType in .phone }
        
        let lock = keyButton.rx.tap
            .map { _ -> SettingsServiceType in .domophone }
        
        let camera = eyeButton.rx.tap
            .map { _ -> SettingsServiceType in .cctv }
        
        Observable.merge(internet, tv, phone, lock, camera)
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }
    
    func configure(with serviceStates: [SettingsServiceType: Bool]) {
        wifiButton.isSelected = serviceStates[.internet] == true
        wifiButton.isEnabled = serviceStates[.internet] != nil
        
        monitorButton.isSelected = serviceStates[.iptv] == true
        monitorButton.isEnabled = serviceStates[.iptv] != nil
        
        callButton.isSelected = serviceStates[.phone] == true
        callButton.isEnabled = serviceStates[.phone] != nil
        
        keyButton.isSelected = serviceStates[.domophone] == true
        keyButton.isEnabled = serviceStates[.domophone] != nil
        
        eyeButton.isSelected = serviceStates[.cctv] == true
        eyeButton.isEnabled = serviceStates[.cctv] != nil
    }
    
    private func configureButtons() {
        wifiButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.internet.unselectedIcon,
            imageForSelected: SettingsServiceType.internet.selectedIcon
        )
        
        monitorButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.iptv.unselectedIcon,
            imageForSelected: SettingsServiceType.iptv.selectedIcon
        )
        
        callButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.phone.unselectedIcon,
            imageForSelected: SettingsServiceType.phone.selectedIcon
        )
        
        keyButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.domophone.unselectedIcon,
            imageForSelected: SettingsServiceType.domophone.selectedIcon
        )
        
        eyeButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.cctv.unselectedIcon,
            imageForSelected: SettingsServiceType.cctv.selectedIcon
        )
    }

}
