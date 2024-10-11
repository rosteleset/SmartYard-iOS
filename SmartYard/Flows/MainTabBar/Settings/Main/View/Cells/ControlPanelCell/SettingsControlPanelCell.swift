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
    @IBOutlet private weak var ctvButton: UIButton!
    @IBOutlet private weak var keyButton: UIButton!
    @IBOutlet private weak var eyeButton: UIButton!
    @IBOutlet private weak var barrierButton: UIButton!

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
        
        let ctv = ctvButton.rx.tap
            .map { _ -> SettingsServiceType in .ctv }
        
        let domophone = keyButton.rx.tap
            .map { _ -> SettingsServiceType in .domophone }
        
        let camera = eyeButton.rx.tap
            .map { _ -> SettingsServiceType in .cctv }
        
        let barrier = barrierButton.rx.tap
            .map { _ -> SettingsServiceType in .barrier }

        Observable.merge(internet, tv, ctv, domophone, camera, barrier)
            .bind(to: outerSubject)
            .disposed(by: disposeBag)
    }
    
    func configure(with serviceStates: [SettingsServiceType: Bool]) {
        wifiButton.isSelected = serviceStates[.internet] == true
        wifiButton.isEnabled = serviceStates[.internet] != nil
        
        monitorButton.isSelected = serviceStates[.iptv] == true
        monitorButton.isEnabled = serviceStates[.iptv] != nil

        ctvButton.isSelected = serviceStates[.ctv] == true
        ctvButton.isEnabled = serviceStates[.ctv] != nil
        
        keyButton.isSelected = serviceStates[.domophone] == true
        keyButton.isEnabled = serviceStates[.domophone] != nil
        
        eyeButton.isSelected = serviceStates[.cctv] == true
        eyeButton.isEnabled = serviceStates[.cctv] != nil
        
        barrierButton.isSelected = serviceStates[.barrier] == true
        barrierButton.isEnabled = serviceStates[.barrier] != nil
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
        
        ctvButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.ctv.unselectedIcon,
            imageForSelected: SettingsServiceType.ctv.selectedIcon
        )
        
        keyButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.domophone.unselectedIcon,
            imageForSelected: SettingsServiceType.domophone.selectedIcon
        )
        
        eyeButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.cctv.unselectedIcon,
            imageForSelected: SettingsServiceType.cctv.selectedIcon
        )
        
        barrierButton.configureSelectableButton(
            imageForNormal: SettingsServiceType.barrier.unselectedIcon,
            imageForSelected: SettingsServiceType.barrier.selectedIcon
        )
    }

}
