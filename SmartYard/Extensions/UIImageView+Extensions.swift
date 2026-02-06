//
//  UIImageView+Extensions.swift
//  SmartYard
//
//  Created by Александр Попов on 16.01.2026.
//  Copyright © 2026 LanTa. All rights reserved.
//

import Kingfisher
import UIKit
import ObjectiveC

private var syImageKey: UInt8 = 0
private var syTokenKey: UInt8 = 0

extension UIImageView {
    var currentKey: String? {
        get {
            objc_getAssociatedObject(self, &syImageKey) as? String
        }
        set {
            objc_setAssociatedObject(
                self,
                &syImageKey,
                newValue,
                .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }
    }
}

extension UIImageView {
    func setImageWithKF(from url: URL?) {
        kf.cancelDownloadTask()
        image = nil

        guard let url else { return }

        kf.setImage(
            with: url,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        )
    }
}


extension UIImageView {
    var currentToken: UUID? {
        get { objc_getAssociatedObject(self, &syTokenKey) as? UUID }
        set { objc_setAssociatedObject(self, &syTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
