//
//  AddressesSectionModel.swift
//  SmartYard
//
//  Created by admin on 06/02/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import RxDataSources

struct AddressesSectionModel: AnimatableSectionModelType {
    
    let identity: String
    
    var items: [AddressesDataItem]
    
}

extension AddressesSectionModel: SectionModelType {
    
    init(original: AddressesSectionModel, items: [AddressesDataItem]) {
        self = original
        self.items = items
    }
    
}
