//
//  HistorySectionModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 05.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

struct HistorySectionModel: AnimatableSectionModelType {
    
    let identity: Date //дата. Допустимые значения: "Y-m-d"
    var day: Date {
        get {
            return identity
        }
    }
    let itemsCount: Int //количество событий
    
    var items: [HistoryDataItem]
    
}

extension HistorySectionModel: SectionModelType {
    
    init(original: HistorySectionModel, items: [HistoryDataItem]) {
        self = original
        self.items = items
    }
    
}

