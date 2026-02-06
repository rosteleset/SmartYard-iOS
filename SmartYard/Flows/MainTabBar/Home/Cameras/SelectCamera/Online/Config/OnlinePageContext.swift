//
//  OnlinePageInput.swift
//  SmartYard
//
//  Created by Александр Попов on 07.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import RxRelay

struct OnlinePageContext {
    let cameras: BehaviorRelay<[CameraViewModel]>
    let preselectedCameraId: BehaviorRelay<CameraID?>
}
