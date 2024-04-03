//
//  SafeFadeCachedImage.swift
//  SmartYard
//
//  Created by Александр Попов on 29.02.2024.
//  Copyright © 2024 LanTa. All rights reserved.
//

import Foundation
import UIKit

class AutoRefreshingCachedImageView: SafeCachedImageView {
    
    private var timer: Timer?
    
    override func loadImageUsingUrlString(urlString: String,
                                          cache: NSCache<NSString, UIImage>,
                                          label: UILabel?,
                                          errorMessage: String = "",
                                          rect: CGRect? = nil,
                                          rectColor: UIColor = .clear) {
        super.loadImageUsingUrlString(
            urlString: urlString,
            cache: cache,
            label: label,
            errorMessage: errorMessage,
            rect: rect,
            rectColor: rectColor
        )
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                guard let self = self,
                      let urlString = self.imageUrlString else { return }
                self.loadImageUsingUrlString(
                    urlString: urlString,
                    cache: cache,
                    label: label,
                    errorMessage: errorMessage, 
                    rect: rect,
                    rectColor: rectColor
                )
            }
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }
}
