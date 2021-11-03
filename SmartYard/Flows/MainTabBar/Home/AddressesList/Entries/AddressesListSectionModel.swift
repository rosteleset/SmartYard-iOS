//
//  AddressesSectionModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

struct AddressesListSectionModel: AnimatableSectionModelType {
    
    let identity: String
    
    var items: [AddressesListDataItem]
    
}

extension AddressesListSectionModel: SectionModelType {
    
    init(original: AddressesListSectionModel, items: [AddressesListDataItem]) {
        self = original
        self.items = items
    }
    
}
