//
//  SettingsSectionModel.swift
//  SmartYard
//
//  Created by admin on 10/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

struct SettingsSectionModel: AnimatableSectionModelType {
    
    let identity: String
    
    var items: [SettingsDataItem]
    
}

extension SettingsSectionModel: SectionModelType {
    
    init(original: SettingsSectionModel, items: [SettingsDataItem]) {
        self = original
        self.items = items
    }
    
}
