//
//  CameraNumberCellViewModel.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

struct CameraNumberCellViewModel: Equatable {
    let cameraId: CameraID
    let number: Int

    var title: String { String(number) }
}
