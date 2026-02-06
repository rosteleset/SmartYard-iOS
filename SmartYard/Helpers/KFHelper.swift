//
//  KFHelper.swift
//  SmartYard
//
//  Created by Александр Попов on 16.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Kingfisher

func configureImageCache() {
    let cache = ImageCache.default

    cache.diskStorage.config.expiration = .days(1)

    cache.memoryStorage.config.expiration = .seconds(2 * 60 * 60) // 2 hours

    cache.memoryStorage.config.totalCostLimit = 60 * 1024 * 1024  // ~60MB
    cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024        // ~200MB
}
