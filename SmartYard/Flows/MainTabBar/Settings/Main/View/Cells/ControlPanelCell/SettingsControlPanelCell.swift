//
//  SettingsControlPanelCell.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
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
            .map { _ -> SettingsServiceType in .tv }
        
        let phone = callButton.rx.tap
            .map { _ -> SettingsServiceType in .phone }
        
        let lock = keyButton.rx.tap
            .map { _ -> SettingsServiceType in .lock }
        
        let camera = eyeButton.rx.tap
            .map { _ -> SettingsServiceType in .camera }
        
        Observable.merge(internet, tv, phone, lock, camera)
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }
    
    func configure(with serviceStates: [SettingsServiceType: SettingsServiceState]) {
        wifiButton.isSelected = serviceStates[.internet] == .activated
        wifiButton.isEnabled = serviceStates[.internet] != nil
        
        monitorButton.isSelected = serviceStates[.tv] == .activated
        monitorButton.isEnabled = serviceStates[.tv] != nil
        
        callButton.isSelected = serviceStates[.phone] == .activated
        callButton.isEnabled = serviceStates[.phone] != nil
        
        keyButton.isSelected = serviceStates[.lock] == .activated
        keyButton.isEnabled = serviceStates[.lock] != nil
        
        eyeButton.isSelected = serviceStates[.camera] == .activated
        eyeButton.isEnabled = serviceStates[.camera] != nil
    }
    
    private func configureButtons() {
        wifiButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.internet.unselectedIcon,
            imageForSelected: SettingsServiceType.internet.selectedIcon
        )
        
        monitorButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.tv.unselectedIcon,
            imageForSelected: SettingsServiceType.tv.selectedIcon
        )
        
        callButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.phone.unselectedIcon,
            imageForSelected: SettingsServiceType.phone.selectedIcon
        )
        
        keyButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.lock.unselectedIcon,
            imageForSelected: SettingsServiceType.lock.selectedIcon
        )
        
        eyeButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.camera.unselectedIcon,
            imageForSelected: SettingsServiceType.camera.selectedIcon
        )
    }

}
