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
    let selectedIndex: Int
}

struct CameraViewModel {
    let identity: String
    let id: CameraID
    let number: Int
    let resource: SYPlayerResource
    let isMuted: Bool
}

extension CameraViewModel {
    var cameraCell: CameraViewCellModel {
        return CameraViewCellModel(
            identity: identity,
            id: id,
            isMuted: isMuted
        )
    }

    var numberCell: CameraNumberCellViewModel {
        return CameraNumberCellViewModel(
            identity: identity,
            cameraId: id,
            number: number
        )
    }
}
