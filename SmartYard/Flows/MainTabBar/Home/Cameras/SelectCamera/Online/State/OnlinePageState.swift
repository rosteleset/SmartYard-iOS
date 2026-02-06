//
//  OnlinePageState.swift
//  SmartYard
//
//  Created by Александр Попов on 25.12.2025.
//  Copyright © 2025 LanTa. All rights reserved.
//

import SmartYardVideoPlayer

typealias CameraID = Int

struct OnlinePageState {
    let cameras: [CameraViewModel]
    let selectedCameraId: CameraID
}

struct CameraViewModel {
    let id: CameraID
    let number: Int
    let resource: SYPlayerResource
    let isMuted: Bool
}

extension CameraViewModel {
    var cameraCell: CameraViewCellModel {
        return CameraViewCellModel(
            id: id,
            isMuted: isMuted
        )
    }

    var numberCell: CameraNumberCellViewModel {
        return CameraNumberCellViewModel(
            cameraId: id,
            number: number
        )
    }
}
