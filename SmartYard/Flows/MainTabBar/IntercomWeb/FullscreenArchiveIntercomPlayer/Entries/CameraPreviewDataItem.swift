//
//  CameraPreviewDataItem.swift
//  SmartYard
//
//  Created by devcentra on 04.10.2023.
//  Copyright © 2023 LanTa. All rights reserved.
//

import RxDataSources

struct CameraPreviewDataItem: IdentifiableType, Equatable {
    let identity: String
    let order: CameraPreviewCellOrder
    let value: APICCTV
}
