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

protocol ImageProviding {
    func setImage(
        on imageView: UIImageView,
        key: String,
        source: ImageSource,
        completion: ((UIImage?) -> Void)?
    )

     func cancel(on imageView: UIImageView)
}
