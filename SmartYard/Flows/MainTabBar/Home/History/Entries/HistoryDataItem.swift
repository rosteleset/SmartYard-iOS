//
//  HistoryDataItem.swift
//  SmartYard
//
//  Created by Александр Васильев on 05.04.2021.
//  Copyright © 2021 LanTa. All rights reserved.
//

import RxDataSources

struct HistoryDataItem: IdentifiableType, Equatable {
    let identity: String
    let order: HistoryCellOrder
    let value: APIPlog
}
