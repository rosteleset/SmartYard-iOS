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
    /// дата. Допустимые значения: "Y-m-d"
    let identity: Date
    var day: Date {
        return identity
    }
    
    /// количество событий
    let itemsCount: Int
    var state: LoadingState = .waiting
    var items: [HistoryDataItem]
}

extension HistorySectionModel: SectionModelType {
    
    init(original: HistorySectionModel, items: [HistoryDataItem]) {
        self = original
        self.items = items
    }
}

