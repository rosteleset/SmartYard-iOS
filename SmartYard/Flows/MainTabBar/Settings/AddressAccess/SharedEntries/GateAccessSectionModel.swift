//
//  GateAccessSectionModel.swift
//  SmartYard
//
//  Created by Александр Попов on 11.06.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import RxDataSources

struct GateAccessSectionModel: AnimatableSectionModelType {
    
    let identity: String
    
    var items: [GateAccessDataItem]
    
}

extension GateAccessSectionModel: SectionModelType {
    
    init(original: GateAccessSectionModel, items: [GateAccessDataItem]) {
        self = original
        self.items = items
    }
    
}
