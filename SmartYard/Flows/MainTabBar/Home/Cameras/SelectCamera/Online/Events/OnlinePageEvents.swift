//
//  OnlinePageEvents.swift
//  SmartYard
//
//  Created by Александр Попов on 06.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import RxRelay

final class OnlinePageEvents {
    // life cycle
    let viewDidLoad = PublishRelay<Void>()
    let viewWillAppear = PublishRelay<Void>()
    let viewDidAppear = PublishRelay<Void>()
    let viewWillDisappear = PublishRelay<Void>()

    // actions

    /// top carousel (cameras)
    let didCenterMainIndex = PublishRelay<Int>()

    /// bottom grid (numbers)
    let didTapPreviewIndex = PublishRelay<Int>()
}
