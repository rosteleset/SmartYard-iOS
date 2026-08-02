//
//  ImageSource.swift
//  SmartYard
//
//  Created by Александр Попов on 16.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import UIKit

enum ImageSource {
    case remoteImage(URL)      // jpg/png/... -> Kingfisher
    case videoThumbnail(URL)   // mp4 -> AVAssetImageGenerator (VideoThumbnailLoader)
}

enum ImageCachePolicy {
    case standard
    case refresh(after: TimeInterval)
}

protocol ImageProviding {
    func setImage(
        on imageView: UIImageView,
        key: String,
        source: ImageSource,
        cachePolicy: ImageCachePolicy,
        completion: ((UIImage?) -> Void)?
    )

    func cancel(on imageView: UIImageView)
}
