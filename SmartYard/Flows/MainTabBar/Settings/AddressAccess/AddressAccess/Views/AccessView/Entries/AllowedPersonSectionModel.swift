//
//  AllowedPersonSectionModel.swift
//  SmartYard
//
//  Created by admin on 19/02/2020.
//  Copyright © 2021 Sesameware. All rights reserved.
//

import RxDataSources

struct AllowedPersonSectionModel: AnimatableSectionModelType {
    
    let identity: String
    
    var items: [AllowedPersonDataItem]
    
}

extension AllowedPersonSectionModel: SectionModelType {
    
    init(original: AllowedPersonSectionModel, items: [AllowedPersonDataItem]) {
        self = original
        self.items = items
    }
    
}
