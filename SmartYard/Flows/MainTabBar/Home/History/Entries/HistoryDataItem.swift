//
//  HistoryDataItem.swift
//  SmartYard
//
//  Created by Александр Васильев on 05.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

struct HistoryDataItem: IdentifiableType, Equatable {
    static func == (lhs: HistoryDataItem, rhs: HistoryDataItem) -> Bool {
        return lhs.value.uuid == rhs.value.uuid
    }
    
    let value: APIPlog
}

extension HistoryDataItem {
    
    var identity: String {
        return value.uuid
    }
    
}
