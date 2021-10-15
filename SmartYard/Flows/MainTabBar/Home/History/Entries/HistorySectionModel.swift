//
//  HistorySectionModel.swift
//  SmartYard
//
//  Created by Александр Васильев on 05.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources
enum LoadingState: Int {
    case waiting = 0
    case loading = 1
    case loaded = 2
}

struct HistorySectionModel: AnimatableSectionModelType {
    
    let identity: Date //дата. Допустимые значения: "Y-m-d"
    var day: Date {
        return identity
    }
    let itemsCount: Int //количество событий
    var state: LoadingState = .waiting
    var items: [HistoryDataItem]
}

extension HistorySectionModel: SectionModelType {
    
    init(original: HistorySectionModel, items: [HistoryDataItem]) {
        self = original
        self.items = items
    }
}

